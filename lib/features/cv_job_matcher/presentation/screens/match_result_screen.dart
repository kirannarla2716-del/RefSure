// lib/features/cv_job_matcher/presentation/screens/match_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/recommendation_badge.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/score_breakdown_card.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/skills_section.dart';

class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({super.key, required this.result});

  final CvMatchResult result;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Match Analysis'),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Copy summary',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result.providerSummary));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Summary copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ));
          },
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Hero score card ──────────────────────────────────
        SectionCard(
          child: Column(children: [
            MatchScoreRing(result.overallScore, size: 110),
            const SizedBox(height: 14),
            RecommendationBadge(recommendation: result.recommendation, large: true),
            const SizedBox(height: 12),
            // Role detected
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Detected as ', style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecond)),
                Text(result.roleLabel, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Provider summary ─────────────────────────────────
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person_outline, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('For the Provider', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            Text(result.providerSummary, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond, height: 1.6)),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Role understanding ───────────────────────────────
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Role Understanding', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(result.roleUnderstandingSummary, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond, height: 1.6)),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Score breakdown ──────────────────────────────────
        ScoreBreakdownCard(result: result),

        const SizedBox(height: 12),

        // ── Skills ──────────────────────────────────────────
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Skills Analysis', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            SkillsSection(
              title: 'Matched Skills (${result.matchedSkills.length})',
              skills: result.matchedSkills,
              matched: true,
              emptyMessage: 'No required skills explicitly matched',
            ),
            if (result.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 16),
              SkillsSection(
                title: 'Missing Skills (${result.missingSkills.length})',
                skills: result.missingSkills,
                matched: false,
              ),
            ],
          ]),
        ),

        const SizedBox(height: 12),

        // ── Tools ────────────────────────────────────────────
        if (result.matchedTools.isNotEmpty || result.missingTools.isNotEmpty)
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tools & Technology', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              if (result.matchedTools.isNotEmpty) SkillsSection(
                title: 'Matched Tools',
                skills: result.matchedTools,
                matched: true,
              ),
              if (result.missingTools.isNotEmpty) ...[
                const SizedBox(height: 14),
                SkillsSection(
                  title: 'Tool Gaps',
                  skills: result.missingTools,
                  matched: false,
                ),
              ],
            ]),
          ),

        if (result.matchedTools.isNotEmpty || result.missingTools.isNotEmpty)
          const SizedBox(height: 12),

        // ── Match indicators ─────────────────────────────────
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Match Indicators', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _MatchIndicator('Experience Match', result.experienceMatch),
            const SizedBox(height: 8),
            _MatchIndicator('Domain Match', result.domainMatch),
            const SizedBox(height: 8),
            _MatchIndicator('Tools Match', result.toolsMatch),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Strong areas ─────────────────────────────────────
        if (result.strongAreas.isNotEmpty)
          SectionCard(
            child: BulletList(
              title: 'Strong Fit Areas',
              items: result.strongAreas,
              icon: Icons.star_outline,
              iconColor: AppColors.emerald,
              emptyMessage: 'None identified',
            ),
          ),

        if (result.strongAreas.isNotEmpty) const SizedBox(height: 12),

        // ── Weak areas ───────────────────────────────────────
        if (result.weakAreas.isNotEmpty)
          SectionCard(
            child: BulletList(
              title: 'Areas of Concern',
              items: result.weakAreas,
              icon: Icons.warning_amber_outlined,
              iconColor: AppColors.amber,
              emptyMessage: 'No major concerns',
            ),
          ),

        if (result.weakAreas.isNotEmpty) const SizedBox(height: 12),

        // ── Candidate suggestions ────────────────────────────
        SectionCard(
          child: BulletList(
            title: 'Suggestions for Candidate',
            items: result.candidateSuggestions,
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.primary,
            emptyMessage: 'No specific suggestions',
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}

class _MatchIndicator extends StatelessWidget {
  const _MatchIndicator(this.label, this.matched);

  final String label;
  final bool matched;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(
      matched ? Icons.check_circle : Icons.cancel_outlined,
      size: 18,
      color: matched ? AppColors.emerald : AppColors.red,
    ),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.inter(
      fontSize: 13, color: AppColors.textPrimary)),
  ]);
}
