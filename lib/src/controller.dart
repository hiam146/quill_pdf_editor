import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillPdfEditorController {
  final _internalController = QuillController.basic();

  String get plainText => _internalController.document.toPlainText();

  void setText(String text) {
    _internalController.replaceText(
      0,
      _internalController.document.length,
      text,
       TextSelection.collapsed(offset: 0),
    );
  }

QuillController get quillController => _internalController;
}
