import 'package:flutter/material.dart';
import 'package:photo_data_picker/domain/data_picker_state.dart';
import 'package:photo_data_picker/ui/screen/data_picker_screen.dart';

@Deprecated('Use DataPickerScreen instead')
class PhotoDataPicker extends StatelessWidget {
  const PhotoDataPicker({super.key});

  @override
  Widget build(BuildContext context) =>
      DataPickerScreen(state: DataPickerState());
}
