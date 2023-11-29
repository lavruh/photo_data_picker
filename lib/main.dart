import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_data_picker/domain/camera_state.dart';
import 'package:photo_data_picker/domain/camera_state_device.dart';
import 'package:photo_data_picker/domain/recognizer.dart';
import 'package:photo_data_picker/ui/photo_data_picker.dart';

List<CameraDescription> cams = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    cams = await availableCameras();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(Recognizer());
    Get.put<CameraState>(CameraStateDevice(
      flashMode: FlashMode.off,
      cameras: cams,
      tmpFile: File('/storage/emulated/0/tmp.jpg'),
    ));

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PhotoDataPicker(),
    );
  }
}
