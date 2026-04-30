// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class SkillChip extends StatelessWidget {
  final String skill;
  final bool highlight, matched;
  final bool compact;
  const SkillChip(this.skill, {super.key,
    this.highlight = false, this.matched = false, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
    decoration: BoxDecoration(
      color: matched ? AppColors.emeraldLight : highlight ? AppColors.primaryLight : AppColors.bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: matched ? AppColors.emerald.withOpacity(0.4)
            : highlight ? AppColors.primary.withOpacity(0.3)
            : AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (matched) ...[
        const Icon(Icons.check, size: 10, color: AppColors.emerald),
        const SizedBox(width: 3),
      ],
      Text(skill, style: GoogleFonts.inter(
        fontSize: compact ? 11 : 12, fontWeight: FontWeight.w500,
        color: matched ? AppColors.emerald
            : highlight ? AppColors.primary : AppColors.textSecond)),
    ]));
}
