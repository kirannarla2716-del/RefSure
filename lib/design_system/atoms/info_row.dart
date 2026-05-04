// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoRow(this.icon, this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: color ?? AppColors.textHint),
    const SizedBox(width: 4),
    Text(text, style: GoogleFonts.inter(fontSize: 12, color: color ?? AppColors.textSecond)),
  ]);
}
