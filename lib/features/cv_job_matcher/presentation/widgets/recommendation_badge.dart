// lib/features/cv_job_matcher/presentation/widgets/recommendation_badge.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';

class RecommendationBadge extends StatelessWidget {
  const RecommendationBadge({
    super.key,
    required this.recommendation,
    this.large = false,
  });

  final ReferralRecommendation recommendation;
  final bool large;

  Color get _bg => switch (recommendation) {
    ReferralRecommendation.stronglyRecommend => AppColors.emeraldLight,
    ReferralRecommendation.recommend         => AppColors.primaryLight,
    ReferralRecommendation.maybe             => AppColors.amberLight,
    ReferralRecommendation.notRecommended    => AppColors.redLight,
  };

  Color get _fg => switch (recommendation) {
    ReferralRecommendation.stronglyRecommend => AppColors.emerald,
    ReferralRecommendation.recommend         => AppColors.primary,
    ReferralRecommendation.maybe             => AppColors.amber,
    ReferralRecommendation.notRecommended    => AppColors.red,
  };

  String get _label => switch (recommendation) {
    ReferralRecommendation.stronglyRecommend => '✅ Strongly Recommend',
    ReferralRecommendation.recommend         => '👍 Recommend',
    ReferralRecommendation.maybe             => '🤔 Maybe',
    ReferralRecommendation.notRecommended    => '❌ Not Recommended',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 14 : 10,
      vertical: large ? 8 : 4,
    ),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(large ? 10 : 20),
      border: Border.all(color: _fg.withOpacity(0.3)),
    ),
    child: Text(
      _label,
      style: GoogleFonts.inter(
        fontSize: large ? 14 : 12,
        fontWeight: FontWeight.w700,
        color: _fg,
      ),
    ),
  );
}
