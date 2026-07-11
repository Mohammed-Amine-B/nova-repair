import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfPrintFonts {
  const PdfPrintFonts({
    required this.regular,
    required this.bold,
    required this.arabicRegular,
    required this.arabicBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font arabicRegular;
  final pw.Font arabicBold;

  List<pw.Font> get regularFallback => [arabicRegular, arabicBold];

  List<pw.Font> get boldFallback => [arabicBold, arabicRegular];
}

abstract class PdfPrintFontProvider {
  Future<PdfPrintFonts> loadFonts();
}

class AssetPdfPrintFontProvider implements PdfPrintFontProvider {
  const AssetPdfPrintFontProvider();

  static const regularAsset = 'assets/fonts/noto/NotoSans-Regular.ttf';
  static const boldAsset = 'assets/fonts/noto/NotoSans-Bold.ttf';
  static const arabicRegularAsset =
      'assets/fonts/noto/NotoSansArabic-Regular.ttf';
  static const arabicBoldAsset = 'assets/fonts/noto/NotoSansArabic-Bold.ttf';

  static Future<PdfPrintFonts>? _cachedFonts;

  @override
  Future<PdfPrintFonts> loadFonts() {
    return _cachedFonts ??= _loadFonts();
  }

  static Future<PdfPrintFonts> _loadFonts() async {
    final regular = await rootBundle.load(regularAsset);
    final bold = await rootBundle.load(boldAsset);
    final arabicRegular = await rootBundle.load(arabicRegularAsset);
    final arabicBold = await rootBundle.load(arabicBoldAsset);

    return PdfPrintFonts(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
      arabicRegular: pw.Font.ttf(arabicRegular),
      arabicBold: pw.Font.ttf(arabicBold),
    );
  }
}
