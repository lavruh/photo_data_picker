import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';
import 'package:photo_data_picker/ui/widget/data_picker_widget.dart';

class DataPickerScreen extends StatefulWidget {
  DataPickerScreen({super.key, this.meterName})
      : state = Get.find<DataPickerState>();
  final DataPickerState state;
  final String? meterName;

  @override
  State<DataPickerScreen> createState() => _DataPickerScreenState();
}

class _DataPickerScreenState extends State<DataPickerScreen> {
  TextEditingController textCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.state.initCamera();
  }

  @override
  void dispose() {
    super.dispose();
    widget.state.disposeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (f, r) => dispose(),
      child: SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.meterName ?? ""),
            ),
            body: GetBuilder<DataPickerState>(builder: (state) {
              if (textCtrl.text != state.reading.value) {
                textCtrl.text = state.reading.value;
              }
              return SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DataPickerWidget(state: state),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.9),
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
                                        state.reading.value = "";
                                        setState(() {});
                                      },
                                      icon: Icon(Icons.cleaning_services)),
                                  suffix: IconButton(
                                      onPressed: () {
                                        widget.state.returnBackWithValue(
                                            state.reading.value);
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.check))),
                            ),
                          )),
                    ]),
              );
            })),
      ),
    );
  }

  _setValue(String val) {
    widget.state.reading.value = val;
  }
}
