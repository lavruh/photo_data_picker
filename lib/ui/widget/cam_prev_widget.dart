import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:photo_data_picker/domain/camera_state.dart';

class CamPrevWidget extends StatelessWidget {
  const CamPrevWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double devWidth = MediaQuery.of(context).size.width;
    return GetBuilder<CameraState>(builder: (_) {
      Widget child = _blind();
      if ((_.camCtrl != null) && (_.camCtrl!.value.isInitialized)) {
        CameraController controller = _.camCtrl!;
        controller.unlockCaptureOrientation();
        child = SizedBox(
          width: devWidth / _.camCtrl!.value.aspectRatio,
          height: devWidth,
          child: AspectRatio(
              aspectRatio: _.camCtrl!.value.aspectRatio,
              child: CameraPreview(
                controller,
                child: CustomPaint(
                  painter: SelectorRect(),
                ),
              )),
        );
      }
      return SizedBox(
        width: devWidth,
        height: devWidth,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: child,
            ),
          ),
        ),
      );
    });
  }

  Widget _blind() {
    return Container(
      color: Colors.indigo,
      child: const Center(
        child: Text(
          "Camera not init",
        ),
      ),
    );
  }
}

class SelectorRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.6,
          height: size.height * 0.08,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.redAccent
          ..strokeWidth = 3.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
