

import 'package:flutter/services.dart';

class NameInputFormatter extends TextInputFormatter {

  final List<(String, String)> replacements;

  NameInputFormatter({
    required this.replacements
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toLowerCase().trim();
    for ((String, String) replacement in replacements) {
      text = text.replaceAll(replacement.$1, replacement.$2);
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length)
    );
  }

}