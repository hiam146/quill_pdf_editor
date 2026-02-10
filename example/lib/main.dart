import 'package:flutter/material.dart';
import 'package:quill_pdf_editor/quill_pdf_editor.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Quill PDF Editor Example')),
        body: QuillPdfEditor(
          config: QuillPdfEditorConfig(
            enablePdfExport: true,
            enablePdfPreview: true,
            showToolbar: true,
            showTitleField: true,
          ),
        ),
      ),
    );
  }
}
