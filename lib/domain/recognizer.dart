import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';


class Recognizer {
  late File inp;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeReading() async {
    final inputImage = InputImage.fromFile(inp);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    return text;
  }

  String cleanString(String inp) {
    return inp.replaceAll(RegExp(r'[a-z \W]', caseSensitive: false), "");
  }
}
