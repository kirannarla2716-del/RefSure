// lib/screens/match_detail_screen.dart
// Full match breakdown — shows why a candidate scored a particular score
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchReport report;
  final String jobTitle;
  final String company;
  final String? seekerName;

  const MatchDetailScreen({super.key,
    required this.report, required this.jobTitle,
    required this.company, this.seekerName});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Match Analysis'),
        Text(jobTitle, style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w400)),
      ]),
    ),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      // ── Score hero ─────────────────────────────────────────
      SectionCard(child: Column(children: [
        if (seekerName != null)
          Text(seekerName!, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        MatchScoreRing(report.score, size: 100),
        const SizedBox(height: 12),
        MatchBandPill(band: report.band, label: report.bandLabel, large: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
          child: Text(report.recommendation, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecond, height: 1.5),
            textAlign: TextAlign.center)),
      ])),

      const SizedBox(height: 12),

      // ── Score breakdown ────────────────────────────────────
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Score Breakdown', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _ScoreBar('Skills Match', report.skillScore, 40, AppColors.primary),
        const SizedBox(height: 12),
        _ScoreBar('Experience', report.experienceScore, 20, AppColors.emerald),
        const SizedBox(height: 12),
        _ScoreBar('Location / Mode', report.locationScore, 15, AppColors.amber),
        const SizedBox(height: 12),
        _ScoreBar('Context & Relevance', report.contextScore, 25, AppColors.accent),
      ])),

      const SizedBox(height: 12),

      // ── Skills ────────────────────────────────────────────
      if (report.matchedSkills.isNotEmpty || report.missingSkills.isNotEmpty)
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Skills Analysis', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          if (report.matchedSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text('${report.matchedSkills.length} matched skills',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.emerald)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: report.matchedSkills.map((s) => SkillChip(s, matched: true)).toList()),
          ],
          if (report.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.cancel_outlined, size: 14, color: AppColors.red),
              const SizedBox(width: 6),
              Text('${report.missingSkills.length} missing skills',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.red)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: report.missingSkills.map((s) => SkillChip(s)).toList()),
          ],
        ])),

      const SizedBox(height: 12),

      // ── Strengths ──────────────────────────────────────────
      if (report.strengths.isNotEmpty)
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Strengths', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.emerald)),
          const SizedBox(height: 10),
          ...report.strengths.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.star, size: 14, color: AppColors.emerald),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond))),
            ]))),
        ])),

      const SizedBox(height: 12),

      // ── Gaps ───────────────────────────────────────────────
      if (report.gaps.isNotEmpty)
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Areas to Address', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.amber)),
          const SizedBox(height: 10),
          ...report.gaps.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber, size: 14, color: AppColors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text(g, style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond))),
            ]))),
        ])),

      const SizedBox(height: 24),
    ]),
  );
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score, max;
  final Color color;
  const _ScoreBar(this.label, this.score, this.max, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecond))),
      Text('$score / $max', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
    const SizedBox(height: 6),
    LinearPercentIndicator(
      percent: score / max, lineHeight: 8, padding: EdgeInsets.zero,
      backgroundColor: color.withOpacity(0.15), progressColor: color,
      barRadius: const Radius.circular(4), animation: true),
  ]);
}
