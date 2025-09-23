import 'package:flutter/material.dart';

/// Widget dropdown yang bisa dipakai ulang
class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final void Function(T?) onChanged;
  final String hint;

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    this.hint = 'Pilih salah satu',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: hint,
      ),
      isExpanded: true,
      value: value,
      onChanged: onChanged,
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
          .toList(),
    );
  }
}
