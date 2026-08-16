// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class ProfileCompletenessBar extends StatelessWidget {
  final int percent;
  const ProfileCompletenessBar(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    final safePercent = percent.clamp(0, 100);
    final color = safePercent >= 80
        ? AppColors.emerald
        : safePercent >= 60
            ? AppColors.primary
            : AppColors.amber;
    return Semantics(
        label: 'Profile strength',
        value: '$safePercent percent',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Profile Strength',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecond)),
            const Spacer(),
            Text('$safePercent%',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: safePercent / 100,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.15),
                  color: color)),
        ]));
  }
}
