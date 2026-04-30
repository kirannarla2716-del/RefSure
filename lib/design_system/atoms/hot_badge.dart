// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

/// Compact "HOT" indicator for trending or urgent jobs.
///
/// Uses the brand sea-green tone with a white pill — readable on light cards
/// and consistent with the rest of the chip family.
class HotBadge extends StatelessWidget {
  const HotBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primary, borderRadius: BorderRadius.circular(4),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.local_fire_department_outlined,
          size: 11, color: Colors.white),
      const SizedBox(width: 3),
      Text('HOT', style: GoogleFonts.inter(
        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white,
        letterSpacing: 0.5,
      )),
    ]),
  );
}
