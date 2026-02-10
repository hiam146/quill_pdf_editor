import 'package:flutter/material.dart';

enum QuillToolbarVerticalPosition { top, bottom }

/// Configuration options for [QuillPdfEditor].
///
/// Allows customization of the editor UI, toolbar,
/// title field, and PDF export behavior.
class QuillPdfEditorConfig {
  final bool enablePdfPreview;
  final bool enablePdfExport;

  final bool showToolbar;
  final QuillToolbarVerticalPosition toolbarPosition;
  final Color toolbarBackgroundColor;
  final double borderRadius;
  final List<BoxShadow> toolbarShadow;

  // Editor
  final Color editorBackgroundColor;
  final double editorPadding;
  final List<BoxShadow> editorShadow;

  // Title
  final bool showTitleField;
  final TextStyle titleTextStyle;
  final TextAlign titleAlignment;
  final Color titleBackgroundColor;
  final EdgeInsets titlePadding;

  // Custom Widgets
  final Widget? previewWidget;
  final Widget? saveWidget;

  const QuillPdfEditorConfig({
    this.enablePdfPreview = true,
    this.enablePdfExport = true,
    this.showToolbar = true,
    this.toolbarPosition = QuillToolbarVerticalPosition.top,
    this.toolbarBackgroundColor = Colors.white,
    this.borderRadius = 12,
    this.toolbarShadow = const [
      BoxShadow(color: Colors.black12, blurRadius: 5),
    ],
    this.editorBackgroundColor = Colors.white,
    this.editorPadding = 30,
    this.editorShadow = const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
    this.showTitleField = true,
    this.titleTextStyle = const TextStyle(fontSize: 20, color: Colors.black),
    this.titleAlignment = TextAlign.center,
    this.titleBackgroundColor = Colors.transparent,
    this.titlePadding = const EdgeInsets.all(8),

    this.previewWidget,
    this.saveWidget,
  });
}
