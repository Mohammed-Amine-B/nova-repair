import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../application/print_document_renderer.dart';
import '../../application/rendered_print_document.dart';
import '../../domain/entities/customer_ticket_data.dart';
import '../../domain/entities/device_label_data.dart';
import '../../domain/entities/repair_print_data.dart';
import '../../infrastructure/qr/qr_code_svg.dart';
import '../../presentation/print_document_mode.dart';
import 'pdf_print_fonts.dart';

class RepairPdfDocumentRenderer implements PrintDocumentRenderer {
  const RepairPdfDocumentRenderer({
    this.compress = true,
    this.fontProvider = const AssetPdfPrintFontProvider(),
  });

  static const PdfPageFormat customerTicketFormat = PdfPageFormat.roll80;
  static const PdfPageFormat deviceLabelFormat = PdfPageFormat(
    60 * PdfPageFormat.mm,
    40 * PdfPageFormat.mm,
    marginAll: 3 * PdfPageFormat.mm,
  );

  final bool compress;
  final PdfPrintFontProvider fontProvider;

  @override
  Future<RenderedPrintDocument> render({
    required RepairPrintData printData,
    required QrCodeSvg qrCode,
    required PrintDocumentMode documentMode,
  }) async {
    final fonts = await fontProvider.loadFonts();

    return switch (documentMode) {
      PrintDocumentMode.customerTicket => _renderCustomerTicket(
        printData.customerTicket,
        qrCode,
        fonts,
      ),
      PrintDocumentMode.deviceLabel => _renderDeviceLabel(
        printData.customerTicket,
        printData.deviceLabel,
        qrCode,
        fonts,
      ),
    };
  }

  Future<RenderedPrintDocument> _renderCustomerTicket(
    CustomerTicketData ticket,
    QrCodeSvg qrCode,
    PdfPrintFonts fonts,
  ) async {
    final document = pw.Document(
      compress: compress,
      title: 'Customer Ticket ${ticket.repairCode}',
      creator: 'Nova Repair',
    );

    document.addPage(
      pw.Page(
        pageFormat: customerTicketFormat,
        build: (context) {
          return pw.DefaultTextStyle(
            style: _textStyle(fonts, fontSize: 9),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _text(
                  ticket.shopName,
                  fonts,
                  textAlign: pw.TextAlign.center,
                  style: _textStyle(fonts, fontSize: 14, bold: true),
                ),
                if (_hasText(ticket.shopSubtitle))
                  _text(
                    ticket.shopSubtitle!,
                    fonts,
                    textAlign: pw.TextAlign.center,
                    style: _textStyle(fonts, fontSize: 10, bold: true),
                  ),
                if (_hasText(ticket.shopPhone))
                  _text(
                    'Phone: ${ticket.shopPhone}',
                    fonts,
                    textAlign: pw.TextAlign.center,
                  ),
                if (_hasText(ticket.shopAddress))
                  _text(
                    'Address: ${ticket.shopAddress}',
                    fonts,
                    textAlign: pw.TextAlign.center,
                  ),
                _divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      child: _field(
                        'Repair Code',
                        ticket.repairCode,
                        fonts,
                        valueStyle: _textStyle(fonts, fontSize: 16, bold: true),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    _field(
                      'Received Date',
                      _formatDate(ticket.receivedAt),
                      fonts,
                      alignEnd: true,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                _field('Customer', _value(ticket.customerName), fonts),
                if (_hasText(ticket.customerPhone))
                  _field('Phone', ticket.customerPhone!, fonts),
                pw.SizedBox(height: 6),
                _field('Device', ticket.deviceDisplayName, fonts),
                _field('Type', _value(ticket.deviceType), fonts),
                _divider(),
                _field('Problem Reported', ticket.reportedProblem, fonts),
                pw.SizedBox(height: 6),
                _field(
                  'Included Accessories',
                  _value(ticket.receivedAccessories),
                  fonts,
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 92,
                        height: 92,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 0.5),
                        ),
                        child: pw.SvgImage(svg: qrCode.svg),
                      ),
                      pw.SizedBox(height: 5),
                      _text(
                        'Scan to track your repair',
                        fonts,
                        style: _textStyle(fonts, bold: true),
                      ),
                      _text(ticket.repairCode, fonts),
                    ],
                  ),
                ),
                if (_hasText(ticket.ticketFooter) ||
                    _hasText(ticket.warrantyTerms)) ...[
                  _divider(),
                  if (_hasText(ticket.ticketFooter))
                    _text(
                      ticket.ticketFooter!,
                      fonts,
                      textAlign: pw.TextAlign.center,
                    ),
                  if (_hasText(ticket.warrantyTerms))
                    _text(
                      ticket.warrantyTerms!,
                      fonts,
                      textAlign: pw.TextAlign.center,
                      style: _textStyle(fonts, bold: true),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );

    return RenderedPrintDocument(
      bytes: await document.save(),
      pageFormat: customerTicketFormat,
      jobName: 'Nova Repair Ticket ${ticket.repairCode}',
    );
  }

  Future<RenderedPrintDocument> _renderDeviceLabel(
    CustomerTicketData ticket,
    DeviceLabelData label,
    QrCodeSvg qrCode,
    PdfPrintFonts fonts,
  ) async {
    final document = pw.Document(
      compress: compress,
      title: 'Device Label ${label.repairCode}',
      creator: 'Nova Repair',
    );

    document.addPage(
      pw.Page(
        pageFormat: deviceLabelFormat,
        build: (context) {
          return pw.DefaultTextStyle(
            style: _textStyle(fonts, fontSize: 7),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _text(
                            ticket.shopName,
                            fonts,
                            maxLines: 1,
                            style: _textStyle(fonts, fontSize: 8, bold: true),
                          ),
                          pw.SizedBox(height: 2),
                          _text(
                            label.repairCode,
                            fonts,
                            maxLines: 1,
                            style: _textStyle(fonts, fontSize: 14, bold: true),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Container(
                      width: 34,
                      height: 34,
                      child: pw.SvgImage(svg: qrCode.svg),
                    ),
                  ],
                ),
                pw.Spacer(),
                _labelRow('Device', label.deviceDisplayName, fonts),
                _labelRow('Customer', _value(label.customerName), fonts),
                _labelRow('Phone', _value(label.customerPhone), fonts),
              ],
            ),
          );
        },
      ),
    );

    return RenderedPrintDocument(
      bytes: await document.save(),
      pageFormat: deviceLabelFormat,
      jobName: 'Nova Repair Label ${label.repairCode}',
    );
  }
}

pw.Widget _field(
  String label,
  String value,
  PdfPrintFonts fonts, {
  pw.TextStyle? valueStyle,
  bool alignEnd = false,
}) {
  return pw.Column(
    crossAxisAlignment: alignEnd
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start,
    children: [
      _text(
        label,
        fonts,
        style: _textStyle(
          fonts,
          fontSize: 7,
          color: PdfColors.grey700,
          bold: true,
        ),
      ),
      _text(value, fonts, style: valueStyle ?? _textStyle(fonts, fontSize: 9)),
    ],
  );
}

pw.Widget _labelRow(String label, String value, PdfPrintFonts fonts) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 42,
          child: _text(
            label,
            fonts,
            style: _textStyle(
              fonts,
              fontSize: 6,
              color: PdfColors.grey700,
              bold: true,
            ),
          ),
        ),
        pw.Expanded(
          child: _text(
            value,
            fonts,
            textAlign: pw.TextAlign.right,
            maxLines: 1,
            style: _textStyle(fonts, bold: true),
          ),
        ),
      ],
    ),
  );
}

pw.Text _text(
  String value,
  PdfPrintFonts fonts, {
  pw.TextStyle? style,
  pw.TextAlign? textAlign,
  int? maxLines,
}) {
  return pw.Text(
    value,
    style: style ?? _textStyle(fonts),
    textAlign: textAlign,
    maxLines: maxLines,
    textDirection: _textDirectionFor(value),
  );
}

pw.TextStyle _textStyle(
  PdfPrintFonts fonts, {
  double? fontSize,
  PdfColor? color,
  bool bold = false,
}) {
  return pw.TextStyle(
    font: bold ? fonts.bold : fonts.regular,
    fontNormal: fonts.regular,
    fontBold: fonts.bold,
    fontFallback: bold ? fonts.boldFallback : fonts.regularFallback,
    fontSize: fontSize,
    color: color,
    fontWeight: bold ? pw.FontWeight.bold : null,
  );
}

pw.TextDirection _textDirectionFor(String value) {
  return _containsArabic(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
}

bool _containsArabic(String value) {
  return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(value);
}

pw.Widget _divider() {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    child: pw.Divider(thickness: 0.5),
  );
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String _value(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = _monthNames[local.month - 1];
  return '$day $month ${local.year}';
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
