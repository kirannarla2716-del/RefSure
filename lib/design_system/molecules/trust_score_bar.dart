// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class TrustScoreBar extends StatelessWidget {
  final double score;
  const TrustScoreBar(this.score, {super.key});

  @override
  Widget build(BuildContext context) {
    final safeScore = score.clamp(0, 100).toDouble();
    final color = safeScore >= 70
        ? AppColors.emerald
        : safeScore >= 40
            ? AppColors.amber
            : AppColors.red;
    final label = safeScore >= 70
        ? 'High Trust'
        : safeScore >= 40
            ? 'Building Trust'
            : 'New';
    return Semantics(
        label: 'Trust score',
        value: '${safeScore.round()} percent, $label',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Trust Score',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecond)),
            const Spacer(),
            Text('${safeScore.round()}  $label',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: safeScore / 100,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.15),
                  color: color)),
        ]));
  }
}
