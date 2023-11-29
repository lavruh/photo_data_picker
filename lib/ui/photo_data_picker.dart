import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_data_picker/ui/screen/camera_screen.dart';

class PhotoDataPicker extends StatelessWidget {
  const PhotoDataPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: CameraScreen(
      ),
    );
  }
}
