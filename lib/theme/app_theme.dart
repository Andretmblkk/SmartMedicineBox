import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Warna Utama ──
  static const Color primaryBlue = Color(0xFF0066FF); 
  static const Color secondaryBlue = Color(0xFFE6F0FF);
  
  // ── Warna Latar Belakang (Selalu Putih) ──
  static const Color lightBg = Colors.white;
  static const Color lightCard = Colors.white;

  // ── Warna Semantik ──
  static const Color success = Color(0xFF00B14F);
  static const Color warning = Color(0xFFFF9900);
  static const Color danger = Color(0xFFE53935);

  // ── Warna Kategori Obat ──
  static const Color pillColor = Color(0xFF0066FF);
  static const Color capsuleColor = Color(0xFF00B14F);

  static Color background(BuildContext context) => lightBg;
  static Color cardBg(BuildContext context) => lightCard;

  static Color textPrimary(BuildContext context) => const Color(0xFF212121);
  static Color textSecondary(BuildContext context) => const Color(0xFF757575);

  // ── Gaya Teks ──
  static TextStyle heading1(BuildContext context) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary(context),
      );

  static TextStyle heading2(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary(context),
      );

  static TextStyle heading3(BuildContext context) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary(context),
      );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary(context),
      );

  static TextStyle bodyBold(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary(context),
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary(context),
      );

  static TextStyle label(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary(context),
      );

  // ── Dekorasi Kartu (Clean & Shadow) ──
  static BoxDecoration cardDecoration(BuildContext context, {double radius = 16}) {
    return BoxDecoration(
      color: cardBg(context),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Gradien Utama ──
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── ThemeData ──
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.light(
          primary: primaryBlue,
          secondary: secondaryBlue,
          surface: lightCard,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: lightCard,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );

  static ThemeData get darkTheme => lightTheme;

  // Fallback for glassDecoration to maintain compatibility during refactor
  static BoxDecoration glassDecoration(BuildContext context, {double radius = 16}) {
    return cardDecoration(context, radius: radius);
  }

  static Color glassOverlay(BuildContext context) => cardBg(context);
  static Color glassBorder(BuildContext context) => Colors.transparent;

  static LinearGradient backgroundGradient(BuildContext context) {
    return LinearGradient(
      colors: [background(context), background(context)],
    );
  }

  static const Color primaryTeal = primaryBlue; // Alias for compatibility
  static const Color accentCyan = secondaryBlue; // Alias for compatibility
}
