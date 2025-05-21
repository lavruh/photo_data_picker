import 'dart:async';
import 'dart:developer' as developer;
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

  DataPickerState({
    this.returnWithValue,
    this.onReadingChanged,
  }) {
    initCamera();
  }

  toggleFlashMode() {
    if ((flashMode.index + 1) == FlashMode.values.length) {
      flashMode = FlashMode.values.first;
    } else {
      flashMode = FlashMode.values[flashMode.index + 1];
    }
    camCtrl?.setFlashMode(flashMode);
    update();
  }

  takePhoto() async {
    isBusy = true;
    update();
    if (!camCtrl!.value.isInitialized) {
      initCamera();
      return null;
    }
    if (camCtrl!.value.isTakingPicture) {
      initCamera();
      return null;
    }
    try {
      XFile pic = await camCtrl!.takePicture();

      final dataImg = await prepareImage(pic);
      recognizeRegion = encodeJpg(dataImg);

      reading = await rec.recognizeReading(
        encodeJpg(dataImg),
        width: dataImg.width,
        height: dataImg.height,
      );
      onReadingChanged?.call(reading);
    } on Exception catch (e) {
      developer.log(e.toString());
    }

    isBusy = false;
    update();
  }

  Future<Image> prepareImage(XFile pic) async {
    Image src = decodeImage(await pic.readAsBytes())!;

    Rect rect = Rect.fromCenter(
      center: Offset(src.width / 2, src.height / 2),
      width: src.width * recognizerRelation.dx,
      height: src.height * recognizerRelation.dy,
    );
    Image pImg = copyCrop(
      src,
      x: rect.topLeft.dx.toInt(),
      y: rect.topLeft.dy.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );
    return pImg;
  }

  void disposeCamera() async {
    if (camCtrl != null) {
      await camCtrl!.dispose();
    }
  }

  void initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        camCtrl = CameraController(cameras.first, ResolutionPreset.max);
      }
    } on CameraException catch (e) {
      developer.log(e.toString());
    }

    if (camCtrl?.value.isInitialized ?? true) {
      return;
    }
    camCtrl?.addListener(() {
      if (camCtrl!.value.hasError) {
        developer.log('Camera error ${camCtrl?.value.errorDescription}');
      }
    });

    try {
      await camCtrl?.initialize();
      await Future.wait([
        camCtrl!.setFlashMode(flashMode),
      ]);
    } on CameraException catch (e) {
      developer.log(e.toString());
    }

    update();
  }

  //Return back reading confirmed by user on screen
  returnBackWithValue() {
    final fnk = returnWithValue;
    if (fnk == null) return;
    fnk(reading);
  }

  void update() => notifyListeners();
}
