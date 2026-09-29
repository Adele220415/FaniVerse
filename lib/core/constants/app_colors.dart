import 'package:flutter/material.dart';

/// The Fandom Verse design palette.
///
/// Values were sampled directly from the PNG mockups rather than eyeballed, so
/// the app matches the designs rather than merely resembling them. The original
/// slate-and-indigo palette was noticeably lighter and bluer than the
/// near-black neutral the designs use, which made cards and fields read as
/// washed out against them.
class AppColors {
  const AppColors._();

  // --- Brand ---------------------------------------------------------------

  /// The signature violet, sampled from the primary button fill (#7C5CFF).
  /// Buttons use this; chips and icon tiles use [primaryTint].
  static const Color primary = Color(0xFF7C5CFF);

  /// Slightly lifted violet, as seen on the pressed/gradient end of a button.
  static const Color primaryDark = Color(0xFF6A48F0);

  static const Color primaryLight = Color(0xFF8B6FFF);

  /// The translucent violet fill behind selected chips, category tags and the
  /// icon tiles inside list rows (#2A2348 over the page background).
  static const Color primaryTint = Color(0xFF2A2348);

  static const Color secondary = Color(0xFF8B6FFF);
  static const Color secondaryDark = Color(0xFF6A48F0);
  static const Color secondaryLight = Color(0xFFA899FF);

  // --- Surfaces ------------------------------------------------------------

  /// The page background: near-black neutral, not navy (#121214).
  static const Color background = Color(0xFF121214);

  /// Raised surfaces - the secondary buttons, sheet backgrounds and fields
  /// that need to sit above the page but below a card (#23232A).
  static const Color elevated = Color(0xFF23232A);

  /// The card fill used throughout the designs (#1B1B20).
  static const Color surface = Color(0xFF1B1B20);
  static const Color card = Color(0xFF1B1B20);

  /// The bottom navigation bar, which the designs make darker than the page
  /// so it separates without a border (#0B0B0D).
  static const Color navBackground = Color(0xFF0B0B0D);

  /// An input field sitting on the page (#151517 to #1B1B20).
  static const Color field = Color(0xFF151517);

  // --- Text ----------------------------------------------------------------

  /// Headings and primary copy (#DBDADF - warm off-white, not pure white).
  static const Color textPrimary = Color(0xFFDBDADF);

  /// Supporting copy under a heading (#8D8C92).
  static const Color textSecondary = Color(0xFF8D8C92);

  /// Placeholders and disabled labels (#6D6D72).
  static const Color textTertiary = Color(0xFF6D6D72);

  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Status --------------------------------------------------------------

  /// The coral-red used for the "Trending now" / "Price dropped" tags. Note
  /// this is a warm red, distinct from the error red.
  static const Color accent = Color(0xFFFF5A5A);

  static const Color success = Color(0xFF3DD68C);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF5A5A);
  static const Color info = Color(0xFF7C5CFF);

  // --- Lines ---------------------------------------------------------------

  /// Hairlines between rows. Deliberately low contrast - the designs separate
  /// cards with spacing and fill, not visible borders.
  static const Color border = Color(0xFF2E2E36);
  static const Color divider = Color(0xFF2E2E36);

  // --- Overlays ------------------------------------------------------------

  static const Color overlay = Color(0xCC0B0B0D);
  static const Color overlayLight = Color(0x66000000);
}
