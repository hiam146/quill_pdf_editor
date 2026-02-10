import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'controller.dart';
import 'editor_config.dart';
import 'pdf_generator.dart';

/// A rich text editor widget with built-in PDF export and preview support.
///
/// This widget encapsulates editing, PDF generation, file saving,
/// and preview logic internally, requiring no additional setup
/// from the consuming application.
class QuillPdfEditor extends StatefulWidget {
  final QuillPdfEditorController? controller;
  final QuillPdfEditorConfig config;

  /// Creates a [QuillPdfEditor] widget.
  ///
  /// The [config] parameter controls the editor behavior,
  /// appearance, and PDF export options.
  const QuillPdfEditor({
    super.key,
    this.controller,
    this.config = const QuillPdfEditorConfig(),
  });

  @override
  State<QuillPdfEditor> createState() => _QuillPdfEditorState();
}

class _QuillPdfEditorState extends State<QuillPdfEditor> {
  late final QuillPdfEditorController _controller;
  final TextEditingController _titleController = TextEditingController(
    text: 'my-file.pdf',
  );
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? QuillPdfEditorController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title field
        if (widget.config.showTitleField)
          Container(
            color: widget.config.titleBackgroundColor,
            padding: widget.config.titlePadding,
            child: TextField(
              controller: _titleController,
              style: widget.config.titleTextStyle,
              textAlign: widget.config.titleAlignment,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
              ),
            ),
          ),

        // Toolbar
        if (widget.config.showToolbar)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.config.toolbarBackgroundColor,
              borderRadius: BorderRadius.circular(widget.config.borderRadius),
              boxShadow: widget.config.toolbarShadow,
            ),
            child: QuillSimpleToolbar(
              controller: _controller.quillController,
              config: QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: true,
                showAlignmentButtons: true,
                multiRowsDisplay: false,
                showUndo: false,
                showRedo: false,
                showDividers: true,
              ),
            ),
          ),

        // Editor
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            decoration: BoxDecoration(
              color: widget.config.editorBackgroundColor,
              borderRadius: BorderRadius.circular(widget.config.borderRadius),
              boxShadow: widget.config.editorShadow,
            ),
            child: QuillEditor.basic(
              controller: _controller.quillController,
              config: QuillEditorConfig(
                padding: EdgeInsets.all(widget.config.editorPadding),
              ),
            ),
          ),
        ),

        // Buttons
        Container(
          height: 100,
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.config.enablePdfPreview)
                if (widget.config.enablePdfPreview)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    onTap: _previewPdf,
                    child: IgnorePointer(
                      ignoring: true,
                      child: widget.config.previewWidget!,
                    ),
                  ),

              if (widget.config.enablePdfExport)
                if (widget.config.enablePdfExport)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    onTap: () {
                      if (_exporting) return;
                      _savePdf();
                    },
                    child: _exporting
                        ? _buildLoader()
                        : IgnorePointer(
                            ignoring: true,
                            child: widget.config.saveWidget!,
                          ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== PDF Actions =====
  Future<void> _previewPdf() async {
    final pdf = await QuillPdfGenerator(
      _controller.quillController,
    ).generateAndExport();
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Widget _buildLoader() {
    return Center(
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 5)),
      ),
    );
  }

  Future<void> _savePdf() async {
    setState(() => _exporting = true);
    final pdf = await QuillPdfGenerator(
      _controller.quillController,
    ).generateAndExport();
    final dir = await getApplicationDocumentsDirectory();

    String baseName = _titleController.text.trim().isEmpty
        ? 'Book'
        : _titleController.text.trim();

    if (baseName.toLowerCase().endsWith('.pdf')) {
      baseName = baseName.substring(0, baseName.length - 4);
    }

    String fileName = '$baseName.pdf';

    int copyIndex = 1;

    while (await File('${dir.path}/$fileName').exists()) {
      copyIndex++;
      fileName = '$baseName($copyIndex).pdf';
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    setState(() => _exporting = false);
    OpenFilex.open(file.path);
  }
}
