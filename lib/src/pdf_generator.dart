import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Callback triggered when a PDF is successfully generated.
typedef PdfGeneratedCallback = void Function(pw.Document pdf);

/// Callback triggered after the PDF export process is completed.
typedef PdfExportCompletedCallback = void Function(Uint8List pdfBytes);

class QuillPdfGenerator {
  final QuillController controller;
  final double pdfMargin;
  final double editorPadding;
  final Map<String, pw.Font>? customFonts;

  QuillPdfGenerator(
    this.controller, {
    this.pdfMargin = 35,
    this.editorPadding = 30,
    this.customFonts,
  });

  // ================= PDF HELPERS =================

  PdfColor _hexToPdfColor(String? hex) {
    if (hex == null) return PdfColors.black;
    try {
      final value = int.parse(hex.substring(1), radix: 16);
      return PdfColor(
        ((value >> 16) & 0xff) / 255,
        ((value >> 8) & 0xff) / 255,
        (value & 0xff) / 255,
      );
    } catch (_) {
      return PdfColors.black;
    }
  }

  bool _isRTL(String text) {
    if (text.trim().isEmpty) return false;
    final code = text.trim().characters.first.codeUnitAt(0);
    return code >= 0x0600 && code <= 0x06FF;
  }

  Future<Map<String, pw.Font>> _loadFonts() async {
    if (customFonts != null) return customFonts!;

    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final boldItalic = await rootBundle.load(
      'assets/fonts/NotoSans-BoldItalic.ttf',
    );
    final italic = await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');

    return {
      'regular': pw.Font.ttf(regular),
      'bold': pw.Font.ttf(bold),
      'italic': pw.Font.ttf(italic),
      'boldItalic': pw.Font.ttf(boldItalic),
    };
  }

  double _parseFontSize(dynamic sizeAttr) {
    if (sizeAttr == 'small') return 9.0;
    if (sizeAttr == 'large') return 18.0;
    if (sizeAttr == 'huge') return 24.0;
    if (sizeAttr is double) return sizeAttr;
    if (sizeAttr is String) return double.tryParse(sizeAttr) ?? 12.0;
    return 12.0;
  }

  pw.TextStyle _getTextStyle(
    Map<String, dynamic> attrs,
    Map<String, pw.Font> fonts,
  ) {
    final isBold = attrs['bold'] == true;
    final isItalic = attrs['italic'] == true;

    double fontSize = _parseFontSize(attrs['size']);
    if (attrs['script'] == 'sub' || attrs['script'] == 'super') fontSize = 8;

    pw.Font selectedFont;
    if (isBold && isItalic) {
      selectedFont = fonts['boldItalic']!;
    } else if (isBold) {
      selectedFont = fonts['bold']!;
    } else if (isItalic) {
      selectedFont = fonts['italic']!;
    } else {
      selectedFont = fonts['regular']!;
    }

    return pw.TextStyle(
      font: selectedFont,
      fontSize: fontSize,
      color: _hexToPdfColor(attrs['color']),
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: pw.TextDecoration.combine([
        if (attrs['underline'] == true) pw.TextDecoration.underline,
        if (attrs['strike'] == true) pw.TextDecoration.lineThrough,
      ]),
      background: attrs['background'] != null
          ? pw.BoxDecoration(color: _hexToPdfColor(attrs['background']))
          : null,
    );
  }

  Future<pw.Widget> _buildLine(
    List<pw.InlineSpan> spans,
    Map<String, dynamic> attrs,
    Map<String, pw.Font> fonts,
    int? listIndex,
  ) async {
    final header = attrs['header'];
    final align = attrs['align'];
    final isCode = attrs['code-block'] == true;
    final isQuote = attrs['blockquote'] == true;
    final listType = attrs['list'];

    double headerFontSize = 12;
    if (header == 1) headerFontSize = 28;
    if (header == 2) headerFontSize = 22;
    if (header == 3) headerFontSize = 18;

    final styledSpans = spans.map((span) {
      final ts = span as pw.TextSpan;
      pw.Font? finalFont = ts.style!.font;
      if (header != null &&
          ts.style!.fontWeight != pw.FontWeight.bold &&
          ts.style!.fontStyle != pw.FontStyle.italic) {
        finalFont = fonts['bold'];
      }
      return pw.TextSpan(
        text: ts.text,
        style: ts.style!.copyWith(
          fontSize: header != null ? headerFontSize : ts.style!.fontSize,
          font: finalFont,
        ),
      );
    }).toList();

    final fullText = spans.map((e) => (e as pw.TextSpan).text ?? '').join();
    final rtl = _isRTL(fullText);

    pw.TextAlign textAlign = rtl ? pw.TextAlign.right : pw.TextAlign.left;
    if (align == 'center') textAlign = pw.TextAlign.center;
    if (align == 'right') textAlign = pw.TextAlign.right;
    if (align == 'left') textAlign = pw.TextAlign.left;

    pw.Widget textWidget = pw.RichText(
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: textAlign,
      text: pw.TextSpan(children: styledSpans),
    );

    pw.Widget lineContent = textWidget;

    if (listType != null) {
      String leading = (listType == 'ordered') ? '$listIndex.' : '•';
      lineContent = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 25,
            child: pw.Text(
              leading,
              textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              style: pw.TextStyle(font: fonts['regular'], fontSize: 12),
            ),
          ),
          pw.Expanded(child: textWidget),
        ],
      );
    }

    pw.Widget lineWidget = lineContent;
    if (isCode || isQuote) {
      lineWidget = pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: isCode ? PdfColors.grey100 : PdfColors.grey50,
          border: isQuote
              ? pw.Border(
                  left: !rtl
                      ? const pw.BorderSide(color: PdfColors.blueGrey, width: 3)
                      : pw.BorderSide.none,
                  right: rtl
                      ? const pw.BorderSide(color: PdfColors.blueGrey, width: 3)
                      : pw.BorderSide.none,
                )
              : null,
          borderRadius: isCode
              ? const pw.BorderRadius.all(pw.Radius.circular(4))
              : null,
        ),
        child: lineWidget,
      );
    }

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: header != null ? 8 : 2),
      child: pw.Container(width: double.infinity, child: lineWidget),
    );
  }

  Future<pw.Document> generateAndExport({
    PdfGeneratedCallback? onPdfGenerated,
    PdfExportCompletedCallback? onExportCompleted,
    bool saveBytes = true,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final delta = controller.document.toDelta();

    final widgets = <pw.Widget>[];
    List<pw.InlineSpan> lineSpans = [];
    int orderedListIndex = 1;

    for (final op in delta.toList()) {
      final attrs = op.attributes ?? {};
      if (op.data is String) {
        final text = op.data as String;
        if (text.contains('\n')) {
          final parts = text.split('\n');
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              lineSpans.add(
                pw.TextSpan(text: parts[i], style: _getTextStyle(attrs, fonts)),
              );
            }
            if (i < parts.length - 1) {
              if (attrs['list'] == 'ordered') {
                widgets.add(
                  await _buildLine(lineSpans, attrs, fonts, orderedListIndex++),
                );
              } else {
                orderedListIndex = 1;
                widgets.add(await _buildLine(lineSpans, attrs, fonts, null));
              }
              lineSpans = [];
            }
          }
        } else {
          lineSpans.add(
            pw.TextSpan(text: text, style: _getTextStyle(attrs, fonts)),
          );
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pdfMargin),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 15),
          child: pw.Text(
            '${context.pageNumber}',
            style: pw.TextStyle(font: fonts['regular'], fontSize: 10),
          ),
        ),
        build: (_) => widgets,
      ),
    );

    onPdfGenerated?.call(pdf);

    if (saveBytes && onExportCompleted != null) {
      final bytes = await pdf.save();
      onExportCompleted(bytes);
    }

    return pdf;
  }

  Future<void> savePdfToFile(String title) async {
    final pdf = await generateAndExport(saveBytes: true);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$title.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFilex.open(file.path);
  }
}
