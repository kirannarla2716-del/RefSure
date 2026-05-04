// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  final bool isOrg;
  const VerifiedBadge({super.key, this.isOrg = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.verified, size: 14, color: isOrg ? AppColors.emerald : AppColors.blue),
    const SizedBox(width: 2),
    Text(isOrg ? 'Org Verified' : 'Verified', style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: isOrg ? AppColors.emerald : AppColors.blue)),
  ]);
}
