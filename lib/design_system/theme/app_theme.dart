// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

ThemeData buildAppTheme() => ThemeData(
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
