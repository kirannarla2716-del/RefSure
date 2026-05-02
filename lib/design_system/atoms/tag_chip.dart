// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class TagChip extends StatelessWidget {
  final String tag;
  const TagChip(this.tag, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.accentLight, borderRadius: BorderRadius.circular(4)),
    child: Text('#$tag', style: GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent)));
}
