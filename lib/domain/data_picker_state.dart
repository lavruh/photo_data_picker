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
    if (isBusy || camCtrl == null || !camCtrl!.value.isInitialized) return;
    if (camCtrl!.value.isTakingPicture) return;

    isBusy = true;
    update();

    try {
      XFile pic = await camCtrl!.takePicture();
      final bytes = await pic.readAsBytes();

      final result = await _processFileInIsolate(bytes);
      if (result != null) {
        recognizeRegion = result.imageBytes;
        reading = await rec.recognizeReading(
          result.imageBytes,
          width: result.width,
          height: result.height,
        );
        onReadingChanged?.call(reading);
      }
    } on Exception catch (e) {
      developer.log("Take photo error: ${e.toString()}");
    } finally {
      isBusy = false;
      update();
    }
  }

  Future<({Uint8List imageBytes, int width, int height})?> _processFileInIsolate(
      Uint8List bytes) async {
    final rel = recognizerRelation;
    return await Isolate.run(() {
      Image? src = decodeImage(bytes);
      if (src == null) return null;

      src = bakeOrientation(src);

      double centerX = src.width / 2;
      double centerY = src.height / 2;
      double w = src.width * rel.dx;
      double h = src.height * rel.dy;

      Image cropped = copyCrop(
        src,
        x: (centerX - w / 2).toInt(),
        y: (centerY - h / 2).toInt(),
        width: w.toInt(),
        height: h.toInt(),
      );

      return (
        imageBytes: encodeJpg(cropped),
        width: cropped.width,
        height: cropped.height,
      );
    });
  }

  void continuesRecognizing() async {
    if (_isContinuous) {
      _isContinuous = false;
      await camCtrl?.stopImageStream();
      update();
      return;
    }

    if (camCtrl == null || !camCtrl!.value.isInitialized) return;

    _isContinuous = true;
    update();

    camCtrl?.startImageStream((CameraImage image) async {
      if (!_isContinuous || isBusy) return;
      isBusy = true;

      try {
        final sensorOrientation = camCtrl?.description.sensorOrientation ?? 0;
        final result = await _processImageInIsolate(image, sensorOrientation);
        if (result != null) {
          recognizeRegion = result.imageBytes;
          reading = await rec.recognizeReading(
            result.imageBytes,
            width: result.width,
            height: result.height,
          );
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

  Future<({Uint8List imageBytes, int width, int height})?>
      _processImageInIsolate(CameraImage image, int sensorOrientation) async {
    final planes = image.planes.map((p) => p.bytes).toList();
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
          bytes: planes[0].buffer,
          order: ChannelOrder.bgra,
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

      return (
        imageBytes: encodeJpg(cropped),
        width: cropped.width,
        height: cropped.height,
      );
    });
  }

  static Image _convertYUV420ToImage(
      List<Uint8List> planes, int width, int height) {
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];

    final img = Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yp = yPlane[yIndex];
        final up = uPlane.length > uvIndex ? uPlane[uvIndex] : 128;
        final vp = vPlane.length > uvIndex ? vPlane[uvIndex] : 128;

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
      if (_isContinuous) {
        await camCtrl!.stopImageStream();
      }
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
