import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// The Fandom Verse theme.
///
/// The mockups are one system: near-black neutral page, cards lifted by fill
/// rather than border, a single violet for anything actionable, and generous
/// vertical rhythm. Nearly every widget in the app previously styled itself
/// inline, which is why screens drifted apart; this centralises the pieces that
/// were being re-implemented - fields, cards, pills, buttons - so a change here
/// propagates everywhere.
class AppTheme {
  const AppTheme._();

  static const double radiusCard = 16;
  static const double radiusTile = 12;
  static const double radiusPill = 999;

  /// Matches the 8pt rhythm the designs use for screen padding.
  static const double gutter = 20;

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,

      // The designs show a near-black app bar that blends into the page, with
      // no elevation shadow.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // The screen-title pattern in the designs: a large bold heading with a
      // muted line of context beneath it. Exposed as a style pair so the
      // heading and its subtitle stay in step.
      textTheme: _textTheme,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        helperStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        // OutlineInputBorder with a 1px hairline; the designs use this on
        // fields, and only on fields.
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.primary),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.elevated,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          // No shadow: the designs use flat fills.
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusTile)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.elevated,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusTile)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Filter chips carry a lot of the designs' filtering UI, so their
      // selected and unselected states are defined once here.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.elevated,
        selectedColor: AppColors.primaryTint,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
        checkmarkColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusTile)),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.elevated,
      ),

      splashFactory: InkSparkle.splashFactory,
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusTile),
      borderSide: BorderSide(color: color),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displaySmall: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
    ),
    headlineSmall: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    // The muted line that sits under every screen heading in the designs.
    bodyMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: AppColors.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );
}
