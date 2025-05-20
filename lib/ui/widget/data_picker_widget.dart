import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';

class DataPickerWidget extends StatelessWidget {
  const DataPickerWidget({super.key, required this.state});
  final DataPickerState state;

  @override
  Widget build(BuildContext context) {
    final busyWidget = SizedBox(
        width: 50,
        height: 50,
        child: Center(child: CircularProgressIndicator()));
    final controller = state.camCtrl;
    if ((controller == null)) return busyWidget;
    if (!controller.value.isInitialized) {
      Timer(Duration(seconds: 1), () => state.initCamera());
      return busyWidget;
    }

    controller.unlockCaptureOrientation();

    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        CameraPreview(
          controller,
          child: CustomPaint(
            painter: SelectorRect(state),
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(25.0),
            child: AnimatedCrossFade(
              firstChild: busyWidget,
              secondChild: FloatingActionButton(
                child: const Icon(Icons.camera),
                onPressed: () => state.takePhoto(),
              ),
              crossFadeState: state.isBusy
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 50),
            )),
      ],
    );
  }
}

class SelectorRect extends CustomPainter {
  SelectorRect(this.state);
  final DataPickerState state;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * state.recognizerRelation.dx,
          height: size.height * state.recognizerRelation.dy,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.redAccent
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
