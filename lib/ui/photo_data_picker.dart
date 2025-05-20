import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_data_picker/ui/screen/data_picker_screen.dart';

class PhotoDataPicker extends StatelessWidget {
  const PhotoDataPicker({super.key});

  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(home: DataPickerScreen());
}
