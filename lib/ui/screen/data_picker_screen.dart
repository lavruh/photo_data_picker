import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';
import 'package:photo_data_picker/ui/widget/data_picker_widget.dart';

class DataPickerScreen extends StatefulWidget {
  const DataPickerScreen({super.key, this.meterName,  this.state});
  final DataPickerState? state;
  final String? meterName;

  @override
  State<DataPickerScreen> createState() => _DataPickerScreenState();
}

class _DataPickerScreenState extends State<DataPickerScreen> {
  final textCtrl = TextEditingController();
  late DataPickerState state;

  @override
  void initState() {
    state = widget.state ?? DataPickerState();
    state.addListener(update);
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    await state.initCamera();
    if (state.isContinuous) {
      state.startContinuesRecognizing();
    }
  }

  void update() => setState(() {});

  @override
  void dispose() {
    super.dispose();
    state.disposeCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (textCtrl.text != state.reading) {
      textCtrl.text = state.reading;
    }

    return PopScope(
      onPopInvokedWithResult: (f, r) => dispose(),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.meterName ?? ""),
            actions: [
              IconButton(
                onPressed: () => _showCameraInfo(),
                icon: const Icon(Icons.info_outline),
                tooltip: "Camera Info",
              ),
              IconButton(
                onPressed: () => state.toggleFlashMode(),
                icon: Icon(state.flashMode == FlashMode.off
                    ? Icons.flash_off
                    : Icons.flash_on),
              ),
              IconButton(
                onPressed: () => state.toggleContinuesRecognizing(),
                icon: Icon(state.isContinuous
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                tooltip: "Continuous Recognition",
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DataPickerWidget(state: state),
                  if (state.recognizeRegion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.memory(
                        state.recognizeRegion!,
                        height: 50,
                      ),
                    ),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: TextField(
                          controller: textCtrl,
                          showCursor: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onSubmitted: _setValue,
                          onChanged: _setValue,
                          decoration: InputDecoration(
                              label: const Text("Reading"),
                              border: const OutlineInputBorder(),
                              prefix: IconButton(
                                  onPressed: () {
                                    state.reading = "";
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.cleaning_services)),
                              suffix: IconButton(
                                  onPressed: () {
                                    state.returnBackWithValue();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.check))),
                        ),
                      )),
                ]),
          ),
        ),
      ),
    );
  }

  void _setValue(String val) {
    state.reading = val;
  }

  void _showCameraInfo() {
    final desc = state.camCtrl?.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Camera Information"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${desc?.name ?? 'Unknown'}"),
            Text("Lens Direction: ${desc?.lensDirection.name ?? 'Unknown'}"),
            Text("Sensor Orientation: ${desc?.sensorOrientation ?? 'Unknown'}°"),
            Text("Image Format: ${state.lastImageFormat ?? 'Waiting for stream...'}"),
            if (state.camCtrl != null)
              Text("Resolution: ${state.camCtrl!.value.previewSize?.width.toInt()}x${state.camCtrl!.value.previewSize?.height.toInt()}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
