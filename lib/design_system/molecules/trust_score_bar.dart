// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class TrustScoreBar extends StatelessWidget {
  final double score;
  const TrustScoreBar(this.score, {super.key});

  Color get _color => score >= 70 ? AppColors.emerald
      : score >= 40 ? AppColors.amber : AppColors.red;

  String get _label => score >= 70 ? 'High Trust'
      : score >= 40 ? 'Building Trust' : 'New';

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('Trust Score', style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecond)),
      const Spacer(),
      Text('${score.round()}  $_label', style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
    ]),
    const SizedBox(height: 6),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100, minHeight: 6, backgroundColor: _color.withOpacity(0.15),
        color: _color)),
  ]);
}
