import 'package:camera/camera.dart';
import 'package:get/get.dart';

abstract class CameraState extends GetxController {
  final reading = "".obs;
  CameraController? camCtrl;
  Function(String val)? returnWithValue;

  toggleFlashMode();
  takePhoto();
  void prepareImage(XFile pic);
  void disposeCamera();
  void initCamera();
  saveState();
  loadState();
  returnBackWithValue(String value);
}
