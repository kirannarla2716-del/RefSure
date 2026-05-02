// lib/features/cv_job_matcher/presentation/widgets/score_breakdown_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';

class ScoreBreakdownCard extends StatelessWidget {
  const ScoreBreakdownCard({super.key, required this.result});

  final CvMatchResult result;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score Breakdown',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _ScoreRow(
          label: 'Core Skills',
          score: result.coreSkillScore,
          maxWeight: 30,
          color: AppColors.emerald,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Role Responsibilities',
          score: result.roleResponsibilityScore,
          maxWeight: 25,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Experience Relevance',
          score: result.experienceScore,
          maxWeight: 15,
          color: AppColors.accent,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Domain Fit',
          score: result.domainScore,
          maxWeight: 10,
          color: AppColors.purple,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Tools & Technology',
          score: result.toolsScore,
          maxWeight: 10,
          color: AppColors.info,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Education & Certs',
          score: result.educationScore,
          maxWeight: 5,
          color: AppColors.gold,
        ),
        const SizedBox(height: 12),
        _ScoreRow(
          label: 'Profile Quality',
          score: result.profileQualityScore,
          maxWeight: 5,
          color: AppColors.amber,
        ),
      ],
    ),
  );
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.maxWeight,
    required this.color,
  });

  final String label;
  final int score;
  final int maxWeight;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecond,
              )),
          ),
          Text('$score / 100',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('×$maxWeight%',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              )),
          ),
        ],
      ),
      const SizedBox(height: 5),
      LinearPercentIndicator(
        percent: (score / 100).clamp(0.0, 1.0),
        lineHeight: 7,
        padding: EdgeInsets.zero,
        backgroundColor: color.withOpacity(0.12),
        progressColor: color,
        barRadius: const Radius.circular(4),
        animation: true,
        animationDuration: 800,
      ),
    ],
  );
}
