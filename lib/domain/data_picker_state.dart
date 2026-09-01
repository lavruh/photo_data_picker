import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

import 'package:photo_data_picker/domain/recognizer.dart';

class DataPickerState extends ChangeNotifier {
  CameraController? camCtrl;
  FlashMode flashMode = FlashMode.off;
  final Function(String val)? returnWithValue;
  // Call back with recognized value after taking photo
  final Function(String val)? onReadingChanged;
  String reading = "";
  final Recognizer rec = Recognizer();
  Uint8List? recognizeRegion;
  final Offset recognizerRelation = Offset(0.6, 0.08);
  bool isBusy = false;
  int _consecutiveReadingCount = 0;
  bool _isContinuous;
  bool get isContinuous => _isContinuous;
  set isContinuous(bool val) {
    _isContinuous = val;
    update();
  }

  DataPickerState({
    this.returnWithValue,
    this.onReadingChanged,
    bool isContinuous = false,
  }) : _isContinuous = isContinuous {
    initCamera();
  }

  void toggleFlashMode() {
    if ((flashMode.index + 1) == FlashMode.values.length) {
      flashMode = FlashMode.values.first;
    } else {
      flashMode = FlashMode.values[flashMode.index + 1];
    }
    camCtrl?.setFlashMode(flashMode);
    update();
  }

  Future<void> takePhoto() async {
    if (_isContinuous) return;

    reading = "";
    _consecutiveReadingCount = 0;
    
    startContinuesRecognizing();

    int elapsed = 0;
    const int step = 100;
    while (elapsed < 3000 && _consecutiveReadingCount < 2) {
      await Future.delayed(const Duration(milliseconds: step));
      elapsed += step;
    }

    await stopContinuesRecognizing();
  }

  void toggleContinuesRecognizing() async {
    if (_isContinuous) {
      stopContinuesRecognizing();
    } else {
      startContinuesRecognizing();
    }
  }

  String? lastImageFormat;

  Future<void> startContinuesRecognizing() async {
    if (camCtrl == null || !camCtrl!.value.isInitialized) return;

    _isContinuous = true;
    update();

    camCtrl?.startImageStream((CameraImage image) async {
      if (!_isContinuous || isBusy) return;
      isBusy = true;

      if (lastImageFormat == null || lastImageFormat != image.format.group.name) {
        lastImageFormat = image.format.group.name;
        update();
      }

      try {
        final sensorOrientation = camCtrl?.description.sensorOrientation ?? 0;
        final result = await _processImageInIsolate(image, sensorOrientation);
        if (result != null) {
          recognizeRegion = result.previewJpg;
          String newReading = await rec.recognizeReading(
            result.rawBgra,
            width: result.width,
            height: result.height,
          );
          
          if (newReading.isNotEmpty && newReading == reading) {
            _consecutiveReadingCount++;
          } else {
            _consecutiveReadingCount = newReading.isNotEmpty ? 1 : 0;
          }
          
          reading = newReading;
          onReadingChanged?.call(reading);
        }
      } catch (e) {
        developer.log("Continuous recognition error: $e");
      } finally {
        isBusy = false;
        update();
      }
    });
  }

  Future<void> stopContinuesRecognizing() async {
    if (_isContinuous) {
      _isContinuous = false;
      await camCtrl?.stopImageStream();
      update();
    }
  }

  Future<({Uint8List previewJpg, Uint8List rawBgra, int width, int height})?>
      _processImageInIsolate(CameraImage image, int sensorOrientation) async {
    final planes = image.planes
        .map((p) => ({
              'bytes': p.bytes,
              'bytesPerRow': p.bytesPerRow,
              'bytesPerPixel': p.bytesPerPixel,
            }))
        .toList();
    final width = image.width;
    final height = image.height;
    final format = image.format.group;
    final rel = recognizerRelation;

    return await Isolate.run(() {
      Image? img;
      if (format == ImageFormatGroup.yuv420) {
        img = _convertYUV420ToImage(planes, width, height);
      } else if (format == ImageFormatGroup.bgra8888) {
        img = Image.fromBytes(
          width: width,
          height: height,
          bytes: (planes[0]['bytes'] as Uint8List).buffer,
          order: ChannelOrder.bgra,
          rowStride: planes[0]['bytesPerRow'] as int?,
        );
      }

      if (img == null) return null;

      // Rotate image based on sensor orientation
      if (sensorOrientation != 0) {
        img = copyRotate(img, angle: sensorOrientation);
      }

      double centerX = img.width / 2;
      double centerY = img.height / 2;
      double w = img.width * rel.dx;
      double h = img.height * rel.dy;

      Image cropped = copyCrop(
        img,
        x: (centerX - w / 2).toInt(),
        y: (centerY - h / 2).toInt(),
        width: w.toInt(),
        height: h.toInt(),
      );

      // Convert to raw BGRA for ML Kit
      final bgraBytes = Uint8List(cropped.width * cropped.height * 4);
      int i = 0;
      for (final pixel in cropped) {
        bgraBytes[i++] = pixel.b.toInt();
        bgraBytes[i++] = pixel.g.toInt();
        bgraBytes[i++] = pixel.r.toInt();
        bgraBytes[i++] = pixel.a.toInt();
      }

      return (
        previewJpg: encodeJpg(cropped),
        rawBgra: bgraBytes,
        width: cropped.width,
        height: cropped.height,
      );
    });
  }

  static Image _convertYUV420ToImage(
      List<dynamic> planes, int width, int height) {
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];

    final Uint8List yBytes = yPlane['bytes'];
    final Uint8List uBytes = uPlane['bytes'];
    final Uint8List vBytes = vPlane['bytes'];

    final int yStride = yPlane['bytesPerRow'];
    final int uvStride = uPlane['bytesPerRow'];
    final int? uvPixelStride = uPlane['bytesPerPixel'];

    final img = Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yStride + x;
        final int uvIndex = (y ~/ 2) * uvStride + (x ~/ 2) * (uvPixelStride ?? 1);

        if (yIndex >= yBytes.length || uvIndex >= uBytes.length || uvIndex >= vBytes.length) {
          continue;
        }

        final yp = yBytes[yIndex];
        final up = uBytes[uvIndex];
        final vp = vBytes[uvIndex];

        int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
            .round()
            .clamp(0, 255);
        int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

        img.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return img;
  }



  void disposeCamera() async {
    if (camCtrl != null) {
      await stopContinuesRecognizing();
      await camCtrl!.dispose();
    }
  }

  Future<void> initCamera() async {
    if (camCtrl != null && camCtrl!.value.isInitialized) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        camCtrl = CameraController(cameras.first, ResolutionPreset.max,
            enableAudio: false);
      }
    } on CameraException catch (e) {
      developer.log(e.toString());
    }

    if (camCtrl == null) return;

    camCtrl?.addListener(() {
      if (camCtrl!.value.hasError) {
        developer.log('Camera error ${camCtrl?.value.errorDescription}');
      }
    });

    try {
      await camCtrl?.initialize();
      await camCtrl!.setFlashMode(flashMode);
    } on CameraException catch (e) {
      developer.log(e.toString());
    }

    update();
  }

  //Return back reading confirmed by user on screen
  void returnBackWithValue() {
    final fnk = returnWithValue;
    if (fnk == null) return;
    fnk(reading);
  }

  void update() => notifyListeners();
}
