// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const Spacer(),
    if (action != null) action!,
  ]);
}
