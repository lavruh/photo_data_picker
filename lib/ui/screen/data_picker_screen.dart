import 'package:flutter/material.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';
import 'package:photo_data_picker/ui/widget/data_picker_widget.dart';

class DataPickerScreen extends StatefulWidget {
  const DataPickerScreen({super.key, this.meterName, required this.state});
  final DataPickerState state;
  final String? meterName;

  @override
  State<DataPickerScreen> createState() => _DataPickerScreenState();
}

class _DataPickerScreenState extends State<DataPickerScreen> {
  final textCtrl = TextEditingController();
  late DataPickerState state;

  @override
  void initState() {
    state = widget.state;
    state.addListener(update);
    super.initState();
    widget.state.initCamera();
  }

  update() => setState(() {});

  @override
  void dispose() {
    super.dispose();
    widget.state.disposeCamera();
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
          ),
          body: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DataPickerWidget(state: state),
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
                                    widget.state.returnBackWithValue();
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

  _setValue(String val) {
    widget.state.reading = val;
  }
}
