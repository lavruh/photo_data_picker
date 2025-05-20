import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';
import 'package:photo_data_picker/ui/photo_data_picker.dart';

List<CameraDescription> cams = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put<DataPickerState>(DataPickerState(returnWithValue: (value) {
      print("\n\n\n\nvalue: $value\n\n\n\n\n");
    }));

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PhotoDataPicker(),
    );
  }
}
