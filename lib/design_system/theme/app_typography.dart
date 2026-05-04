import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class AppTypography {
  static TextStyle get _base => GoogleFonts.inter();

  // Headings
  static TextStyle get h1 => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitle => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // Body
  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySecondary => _base.copyWith(
        fontSize: 13,
        color: AppColors.textSecond,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        color: AppColors.textSecond,
      );

  // Labels & Captions
  static TextStyle get label => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecond,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
      );

  static TextStyle get captionSmall => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      );

  // Buttons
  static TextStyle get button => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get buttonSmall => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );
}
