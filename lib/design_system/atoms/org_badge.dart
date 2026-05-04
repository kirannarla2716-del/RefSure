// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class OrgBadge extends StatelessWidget {
  final String? company;
  const OrgBadge({super.key, this.company});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.emerald.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.domain_verification, size: 12, color: AppColors.emerald),
      const SizedBox(width: 4),
      Text('${company ?? "Org"} Verified', style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emerald)),
    ]));
}
