// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.redLight, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.red.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.red, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: GoogleFonts.inter(
        fontSize: 13, color: AppColors.red))),
    ]),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider()),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('or', style: GoogleFonts.inter(
        fontSize: 12, color: AppColors.textHint))),
    const Expanded(child: Divider()),
  ]);
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: AppColors.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('G', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF4285F4))),
      const SizedBox(width: 10),
      Text('Continue with Google', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    ]),
  );
}

class RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const RoleChip({super.key,
    required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1)),
      alignment: Alignment.center,
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textSecond)),
    ),
  ));
}
