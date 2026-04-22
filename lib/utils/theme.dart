// lib/utils/theme.dart — v2.0 Premium LinkedIn-inspired design system
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';

class AppColors {
  // Brand
  static const primary      = Color(0xFF0A66C2);   // LinkedIn blue
  static const primaryLight = Color(0xFFEBF3FA);
  static const primaryDark  = Color(0xFF004182);
  static const accent       = Color(0xFF7C3AED);   // Purple accent
  static const accentLight  = Color(0xFFF3F0FF);

  // Surface
  static const bg           = Color(0xFFF3F2EF);   // LinkedIn bg
  static const surface      = Colors.white;
  static const surfaceHover = Color(0xFFF9F9F9);
  static const border       = Color(0xFFE0E0E0);
  static const divider      = Color(0xFFE8E8E8);

  // Text
  static const textPrimary  = Color(0xFF191919);
  static const textSecond   = Color(0xFF666666);
  static const textHint     = Color(0xFF999999);

  // Semantic
  static const emerald      = Color(0xFF057642);
  static const emeraldLight = Color(0xFFE9F5EE);
  static const amber        = Color(0xFFB45309);
  static const amberLight   = Color(0xFFFEF3C7);
  static const blue         = Color(0xFF0A66C2);
  static const blueLight    = Color(0xFFEBF3FA);
  static const red          = Color(0xFFCC1016);
  static const redLight     = Color(0xFFFFF0F0);
  static const purple       = Color(0xFF7C3AED);
  static const purpleLight  = Color(0xFFF3F0FF);
  static const gold         = Color(0xFFB8860B);
  static const goldLight    = Color(0xFFFFF8E1);

  // Match band colors
  static Color matchBg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch => const Color(0xFFE9F5EE),
    MatchBand.excellentMatch => const Color(0xFFEBF3FA),
    MatchBand.goodToGo      => const Color(0xFFF3F0FF),
    MatchBand.needsReview   => const Color(0xFFFEF3C7),
    MatchBand.lowMatch      => const Color(0xFFFFF0F0),
  };

  static Color matchFg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch => emerald,
    MatchBand.excellentMatch => blue,
    MatchBand.goodToGo      => purple,
    MatchBand.needsReview   => amber,
    MatchBand.lowMatch      => red,
  };

  // Status colors
  static Color statusBg(String s) => switch (s) {
    'pending'      => const Color(0xFFF3F2EF),
    'underReview'  => blueLight,
    'strongMatch'  => emeraldLight,
    'needsReview'  => amberLight,
    'shortlisted'  => purpleLight,
    'referred'     => emeraldLight,
    'interview'    => blueLight,
    'hired'        => const Color(0xFFE9F5EE),
    'notSelected'  => redLight,
    'closed'       => const Color(0xFFF3F2EF),
    _              => const Color(0xFFF3F2EF),
  };

  static Color statusFg(String s) => switch (s) {
    'pending'      => textHint,
    'underReview'  => blue,
    'strongMatch'  => emerald,
    'needsReview'  => amber,
    'shortlisted'  => purple,
    'referred'     => emerald,
    'interview'    => blue,
    'hired'        => emerald,
    'notSelected'  => red,
    'closed'       => textHint,
    _              => textHint,
  };

  static Color workModeBg(String m) => switch (m) {
    'Remote'  => emeraldLight,
    'Hybrid'  => amberLight,
    'On-site' => blueLight,
    _         => const Color(0xFFF3F2EF),
  };

  static Color workModeFg(String m) => switch (m) {
    'Remote'  => emerald,
    'Hybrid'  => amber,
    'On-site' => blue,
    _         => textSecond,
  };

  static Color matchScoreColor(int score) {
    if (score >= 90) return emerald;
    if (score >= 80) return blue;
    if (score >= 70) return purple;
    if (score >= 60) return amber;
    return red;
  }
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, surface: Colors.white),
  scaffoldBackgroundColor: AppColors.bg,
  textTheme: GoogleFonts.interTextTheme().apply(
    bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white, elevation: 0,
    scrolledUnderElevation: 1, shadowColor: AppColors.border,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    surfaceTintColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: AppColors.border, width: 1)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.red)),
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
    labelStyle: const TextStyle(color: AppColors.textSecond, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textHint,
    elevation: 0,
  ),
);
