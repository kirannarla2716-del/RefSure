// lib/features/cv_job_matcher/presentation/widgets/skills_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/design_system.dart';

/// Renders a labelled list of skill chips — used for both
/// matched skills (green) and missing skills (red/neutral).
class SkillsSection extends StatelessWidget {
  const SkillsSection({
    super.key,
    required this.title,
    required this.skills,
    required this.matched,
    this.emptyMessage = 'None identified',
  });

  final String title;
  final List<String> skills;
  final bool matched;
  final String emptyMessage;

  Color get _fg => matched ? AppColors.emerald : AppColors.red;
  Color get _bg => matched ? AppColors.emeraldLight : AppColors.redLight;
  IconData get _icon => matched ? Icons.check_circle_outline : Icons.cancel_outlined;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(_icon, size: 15, color: _fg),
        const SizedBox(width: 6),
        Text(title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _fg,
          )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${skills.length}',
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: _fg)),
        ),
      ]),
      const SizedBox(height: 10),
      skills.isEmpty
        ? Text(emptyMessage,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint))
        : Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((s) => _SkillPill(label: s, matched: matched)).toList(),
        ),
    ],
  );
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({required this.label, required this.matched});

  final String label;
  final bool matched;

  Color get _bg => matched ? AppColors.emeraldLight : AppColors.redLight;
  Color get _fg => matched ? AppColors.emerald : AppColors.red;
  Color get _border => matched
      ? AppColors.emerald.withOpacity(0.35)
      : AppColors.red.withOpacity(0.35);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (matched) ...[
        Icon(Icons.check, size: 10, color: _fg),
        const SizedBox(width: 4),
      ],
      Text(label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _fg,
        )),
    ]),
  );
}

/// Generic bullet-point list with an icon — used for strong/weak areas
/// and candidate suggestions.
class BulletList extends StatelessWidget {
  const BulletList({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
    this.emptyMessage,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (items.isEmpty && emptyMessage != null)
        Text(emptyMessage!,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint))
      else
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(item,
              style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond, height: 1.4))),
          ]),
        )),
    ],
  );
}
