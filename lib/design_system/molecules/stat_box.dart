// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const StatBox({super.key, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: valueColor ?? AppColors.textPrimary)),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
  ]);
}
