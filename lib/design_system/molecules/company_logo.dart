// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

/// Square monogram for a company. Uses the brand sea-green palette so logos
/// blend with the rest of the design system rather than introducing
/// per-letter palette noise.
class CompanyLogo extends StatelessWidget {
  final String letter;
  final double size;
  const CompanyLogo({super.key, required this.letter, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withOpacity(0.2))),
    alignment: Alignment.center,
    child: Text(letter.toUpperCase(), style: GoogleFonts.inter(
      fontSize: size * 0.45, fontWeight: FontWeight.w900,
      color: AppColors.primary)));
}
