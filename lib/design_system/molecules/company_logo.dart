// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class CompanyLogo extends StatelessWidget {
  final String letter;
  final double size;
  const CompanyLogo({super.key, required this.letter, required this.size});

  Color get _bg {
    const map = {
      'G': Color(0xFF4285F4), 'M': Color(0xFF00A4EF), 'A': Color(0xFFFF9900),
      'F': Color(0xFF1877F2), 'T': Color(0xFF1DA1F2), 'L': Color(0xFF0A66C2),
    };
    return map[letter.toUpperCase()] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: _bg.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _bg.withOpacity(0.2))),
    alignment: Alignment.center,
    child: Text(letter.toUpperCase(), style: GoogleFonts.inter(
      fontSize: size * 0.45, fontWeight: FontWeight.w900, color: _bg)));
}
