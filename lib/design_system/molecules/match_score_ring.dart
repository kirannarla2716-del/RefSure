// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class MatchScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;
  const MatchScoreRing(this.score, {super.key, this.size = 56, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.matchScoreColor(score);
    return CircularPercentIndicator(
      radius: size / 2, lineWidth: size * 0.1,
      percent: score / 100, backgroundColor: color.withOpacity(0.15),
      progressColor: color,
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$score', style: GoogleFonts.inter(
          fontSize: size * 0.28, fontWeight: FontWeight.w800, color: color)),
        if (showLabel) Text('%', style: GoogleFonts.inter(
          fontSize: size * 0.15, color: color)),
      ]),
      animation: true, animationDuration: 800,
    );
  }
}
