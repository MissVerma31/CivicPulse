import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {

  static const primary = Color(0xFF0284C7); // Civic Sapphire
  static const primaryLight = Color(0xFF38BDF8);
  static const primaryHover = Color(0xFF0369A1); // active-state per DESIGN.md Buttons spec
  static const primaryDark = primaryHover; // ALIAS: kept for screens still using the old name
  static const secondary = Color(0xFF10B981); // Resolution Emerald -- resolved, confirmed, success
  static const tertiary = Color(0xFFF59E0B); // Civic Amber -- pending, non-critical alerts, XP


  static const textPrimary = Color(0xFF0F172A); // Deep Slate Navy
  static const textSecondary = Color(0xFF64748B); // muted supporting text, per DESIGN.md
  static const textMuted = Color(0xFF94A3B8); // Slate Gray (placeholders, disabled)

  static const canvas = Color(0xFFF8FAFC); // page background
  static const background = canvas; // ALIAS: kept for screens still using the old name
  static const surface = Color(0xFFFFFFFF); // cards, sheets
  static const border = Color(0xFFE2E8F0); // hairline borders
  static const borderStrong = Color(0xFFCBD5E1); // input borders

  static const resolvedBg = Color(0xFFECFDF5);
  static const resolvedText = Color(0xFF047857);
  static const pendingBg = Color(0xFFFFFBEB);
  static const pendingText = Color(0xFFB45309);
  static const noticeBg = Color(0xFFE0F2FE);
  static const noticeText = Color(0xFF0369A1);
  static const errorColor = Color(0xFFBA1A1A);

  // --- Elevation shadows (Level 1 / Level 2 / Level 3 from DESIGN.md) ---
  static const shadowLevel1 = [
    BoxShadow(color: Color(0x0D0F172A), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x0D0F172A), offset: Offset(0, 1), blurRadius: 2, spreadRadius: -1),
  ];
  static const shadowLevel2 = [
    BoxShadow(color: Color(0x120F172A), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
    BoxShadow(color: Color(0x0D0F172A), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
  ];
}

class AppTheme {
  static ThemeData get theme {
    // Plus Jakarta Sans, per DESIGN.md typography spec. Requires the
    // google_fonts package (already in pubspec.yaml).
    final base = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        error: AppColors.errorColor,
        brightness: Brightness.light,
      ),

      textTheme: base.copyWith(
        // headline-lg
        headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w700, height: 36 / 28,
          letterSpacing: -0.02 * 28, color: AppColors.textPrimary,
        ),
        // headline-md
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 22, fontWeight: FontWeight.w700, height: 28 / 22,
          letterSpacing: -0.015 * 22, color: AppColors.textPrimary,
        ),
        // headline-sm
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18,
          letterSpacing: -0.01 * 18, color: AppColors.textPrimary,
        ),
        // body-lg
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
          color: AppColors.textPrimary,
        ),
        // body-md
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.43,
          color: AppColors.textSecondary,
        ),
        // body-sm
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w400, height: 1.33,
          color: AppColors.textMuted,
        ),
        // label-lg (button text)
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.01 * 14,
        ),
        // label-sm (badges, uppercase microcopy, ticket numbers)
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.04 * 11,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // rounded-2xl per DESIGN.md Shapes
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Primary CTA: Civic Sapphire bg, white text, 12px radius, 48px min height
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Secondary / actionable-neutral button: white surface, slate border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong, width: 1),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    );
  }
}

/// Status badge styling, per DESIGN.md's three badge variants:
/// Resolved/Eco (emerald), Active SLA/In Jeopardy (amber), Under Review/Open (sapphire).
/// Maps a backend status STRING (e.g. "IN_PROGRESS") to the right variant.
class StatusStyle {
  final Color bg;
  final Color text;
  final String label;
  const StatusStyle(this.bg, this.text, this.label);

  /// Accepts both "IN_PROGRESS" (backend string) and "inProgress"
  /// (Dart enum .name) and normalizes to "IN_PROGRESS".
  static String _normalize(String s) {
    return s
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => '_')
        .toUpperCase();
  }

  static StatusStyle fromStatus(String status) {
    switch (_normalize(status)) {
      case 'PENDING_VERIFICATION':
        return const StatusStyle(AppColors.pendingBg, AppColors.pendingText, 'Pending');
      case 'VERIFIED':
        return const StatusStyle(AppColors.noticeBg, AppColors.noticeText, 'Verified');
      case 'IN_PROGRESS':
        return const StatusStyle(AppColors.pendingBg, AppColors.pendingText, 'In Progress');
      case 'RESOLVED':
        return const StatusStyle(AppColors.resolvedBg, AppColors.resolvedText, 'Resolved');
      case 'CLOSED':
        return const StatusStyle(AppColors.resolvedBg, AppColors.resolvedText, 'Closed');
      case 'REJECTED':
        return StatusStyle(AppColors.errorColor.withValues(alpha: 0.08), AppColors.errorColor, 'Rejected');
      default:
        return const StatusStyle(AppColors.pendingBg, AppColors.pendingText, 'Unknown');
    }
  }
}


class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.fromStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: style.text, shape: BoxShape.circle),
          ),
          Text(
            style.label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.04 * 11,
              color: style.text,
            ),
          ),
        ],
      ),
    );
  }
}