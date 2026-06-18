import 'package:pdf/pdf.dart';

/// Constantes partagées entre Flutter Preview et PDF
/// Cela assure la cohérence 100% entre les deux rendus
class PdfConstants {
  // Marges et padding
  static const double pageMarginH = 20.0;
  static const double pageMarginV = 20.0;
  static const double headerPadding = 12.0;
  static const double sectionGap = 12.0;
  
  // Couleurs
  static const PdfColor textDark = PdfColor.fromInt(0xFF202124);
  static const PdfColor textGrey = PdfColor.fromInt(0xFF5F6368);
  static const PdfColor labelGrey = PdfColor.fromInt(0xFF80868B);
  static const PdfColor divider = PdfColor.fromInt(0xFFE8EAED);
  static const PdfColor boxBg = PdfColor.fromInt(0xFFF8F9FA);
  
  // Tailles de police
  static const double fontSmall = 7.0;
  static const double fontBase = 9.0;
  static const double fontMedium = 10.0;
  static const double fontLarge = 12.0;
  static const double fontXLarge = 14.0;
  static const double fontTitle = 16.0;
}