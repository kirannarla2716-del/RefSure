// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class WorkModePill extends StatelessWidget {
  final String mode;
  const WorkModePill(this.mode, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.workModeBg(mode), borderRadius: BorderRadius.circular(20)),
    child: Text(mode, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.workModeFg(mode))));
}
