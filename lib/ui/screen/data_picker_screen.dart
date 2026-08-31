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
      // Toggle it off then on to trigger the stream start
      state.isContinuous = false;
      state.continuesRecognizing();
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
                onPressed: () => state.toggleFlashMode(),
                icon: Icon(state.flashMode == FlashMode.off
                    ? Icons.flash_off
                    : Icons.flash_on),
              ),
              IconButton(
                onPressed: () => state.continuesRecognizing(),
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
}
