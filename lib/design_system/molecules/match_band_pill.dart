// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class MatchBandPill extends StatelessWidget {
  final MatchBand band;
  final String label;
  final bool large;
  const MatchBandPill({super.key, required this.band, required this.label, this.large = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
    decoration: BoxDecoration(
      color: AppColors.matchBg(band), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.matchFg(band).withOpacity(0.3))),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: large ? 13 : 11, fontWeight: FontWeight.w700,
      color: AppColors.matchFg(band))));
}
