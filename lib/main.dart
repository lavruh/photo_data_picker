import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PhotoDataPicker(),
    );
  }
}
