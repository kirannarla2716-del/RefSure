// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.emoji, required this.title,
    required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
          textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ])));
}
