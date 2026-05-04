// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status, label;
  const StatusPill({super.key, required this.status, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.statusBg(status), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.statusFg(status))));
}
