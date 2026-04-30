// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

/// Empty state with a circular icon container, title, and optional action.
///
/// Replaces an earlier emoji-based variant. Pass [icon] (defaults to
/// [Icons.inbox_outlined]) to surface an appropriate symbol per context.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    ),
  );
}
