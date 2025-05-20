import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class Recognizer {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeReading(Uint8List bitmap,
      {required int width, required int height}) async {
    final inputImage =
        InputImage.fromBitmap(bitmap: bitmap, width: width, height: height);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final text = recognizedText.text;
    return text;
  }

  String cleanString(String inp) {
    return inp.replaceAll(RegExp(r'[a-z \W]', caseSensitive: false), "");
  }
}
