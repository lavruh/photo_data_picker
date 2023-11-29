import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image/image.dart';

import 'package:photo_data_picker/domain/camera_state.dart';
import 'package:photo_data_picker/domain/recognizer.dart';

class CameraStateDevice extends GetxController implements CameraState {
  @override
  CameraController? camCtrl;
  late List<CameraDescription> cameras;
  FlashMode flashMode = FlashMode.off;
  @override
  Function(String val)? returnWithValue;

  CameraStateDevice({
    required this.flashMode,
    required this.tmpFile,
    required this.cameras,
    this.returnWithValue,
  }) : camCtrl = cameras.isNotEmpty
            ? CameraController(cameras.first, ResolutionPreset.max)
            : null;

  @override
  final reading = "".obs;
  final rec = Get.find<Recognizer>();
  final File tmpFile;

  @override
  toggleFlashMode() {
    if ((flashMode.index + 1) == FlashMode.values.length) {
      flashMode = FlashMode.values.first;
    } else {
      flashMode = FlashMode.values[flashMode.index + 1];
    }
    camCtrl?.setFlashMode(flashMode);
    update();
  }

  @override
  takePhoto() async {
    Get.snackbar("Camera", "Take photo\n");
    if (!camCtrl!.value.isInitialized) {
      Get.snackbar("Camera", "Controller not init\n");
      initCamera();
      return null;
    }
    if (camCtrl!.value.isTakingPicture) {
      Get.snackbar("Camera", "CameraScreen busy\n");
      initCamera();
      return null;
    }
    try {
      XFile pic = await camCtrl!.takePicture();

      await prepareImage(pic);

      rec.inp = tmpFile;
      reading.value = await rec.recognizeReading();
    } on Exception catch (e) {
      Get.snackbar("Camera", e.toString());
    }
    update();
  }

  @override
  Future prepareImage(XFile pic) async {
    Image img = decodeImage(await pic.readAsBytes())!;

    final src = copyRotate(img, angle: 90);

    Rect rect = Rect.fromCenter(
      center: Offset(src.width / 2, src.height / 2),
      width: src.width * 0.6,
      height: src.height * 0.072,
    );
    Image pImg = copyCrop(
      src,
      x: rect.topLeft.dx.toInt(),
      y: rect.topLeft.dy.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );
    await tmpFile.writeAsBytes(encodeJpg(pImg));
  }

  @override
  void disposeCamera() async {
    if (camCtrl != null) {
      await camCtrl!.dispose();
    }
  }

  @override
  void initCamera() async {
    if (cameras.isNotEmpty) {
      camCtrl = CameraController(cameras[0], ResolutionPreset.max);
    }
    if (camCtrl != null) {
      camCtrl?.addListener(() {
        if (camCtrl!.value.hasError) {
          Get.snackbar(
              "Camera", 'Camera error ${camCtrl?.value.errorDescription}');
        }
      });

      try {
        await camCtrl?.initialize();
        await Future.wait([
          camCtrl!.setFlashMode(flashMode),
        ]);
      } on CameraException catch (e) {
        Get.snackbar("Camera", e.toString());
      }
    }

    update();
  }

  @override
  saveState() async {}

  @override
  loadState() {
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadState();
  }

  @override
  returnBackWithValue(String value) {
    if (returnWithValue != null) {
      returnWithValue!(value);
    }
  }
}
