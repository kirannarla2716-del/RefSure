// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class ProfileCompletenessBar extends StatelessWidget {
  final int percent;
  const ProfileCompletenessBar(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80 ? AppColors.emerald
        : percent >= 60 ? AppColors.primary : AppColors.amber;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Profile Strength', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecond)),
        const Spacer(),
        Text('$percent%', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100, minHeight: 6,
          backgroundColor: color.withOpacity(0.15), color: color)),
    ]);
  }
}
