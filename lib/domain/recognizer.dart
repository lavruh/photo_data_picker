import 'dart:io';

import 'package:google_ml_vision/google_ml_vision.dart';

class Recognizer {
  late File inp;
  final TextRecognizer textRecognizer = GoogleVision.instance.textRecognizer();

  Future<String> recognizeReading() async {
    final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(inp);
    final VisionText visionText =
        await textRecognizer.processImage(visionImage);
    return visionText.text ?? "";
  }

  String cleanString(String inp) {
    return inp.replaceAll(RegExp(r'[a-z \W]', caseSensitive: false), "");
  }
}
