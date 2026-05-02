// lib/features/cv_job_matcher/presentation/widgets/applicant_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/recommendation_badge.dart';
import 'package:timeago/timeago.dart' as timeago;

class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.application,
    required this.onTap,
    this.rank,
  });

  final JobApplication application;
  final VoidCallback onTap;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final match = application.matchResult;
    final score = application.matchScore;
    final color = AppColors.matchScoreColor(score);

    return SectionCard(
      onTap: onTap,
      child: Row(children: [

        // ── Rank badge ────────────────────────────────────
        if (rank != null) ...[
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: rank! <= 3 ? AppColors.goldLight : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border)),
            alignment: Alignment.center,
            child: Text('$rank', style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: rank! <= 3 ? AppColors.gold : AppColors.textHint))),
          const SizedBox(width: 10),
        ],

        // ── Avatar ────────────────────────────────────────
        UserAvatar(name: application.requesterName, size: 44),
        const SizedBox(width: 12),

        // ── Info ──────────────────────────────────────────
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.requesterName, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
            Text(application.requesterEmail, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusBg(application.status),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(application.statusLabel, style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: _statusFg(application.status)))),
              const SizedBox(width: 8),
              // Has CV indicator
              if (application.resumeText.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.description_outlined, size: 11,
                    color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text('CV', style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textHint)),
                ]),
              const SizedBox(width: 8),
              Text(timeago.format(application.appliedAt), style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.textHint)),
            ]),
            // Recommendation badge
            if (match != null) ...[
              const SizedBox(height: 6),
              RecommendationBadge(recommendation: match.recommendation),
            ],
          ],
        )),

        const SizedBox(width: 12),

        // ── Score ring ────────────────────────────────────
        Column(mainAxisSize: MainAxisSize.min, children: [
          MatchScoreRing(score, size: 52),
          const SizedBox(height: 4),
          Text(match?.roleLabel ?? '—', style: GoogleFonts.inter(
            fontSize: 9, color: AppColors.textHint),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),

        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      ]),
    );
  }

  Color _statusBg(ApplicationStatus s) => switch (s) {
    ApplicationStatus.applied     => AppColors.bg,
    ApplicationStatus.underReview => AppColors.infoLight,
    ApplicationStatus.shortlisted => AppColors.primaryLight,
    ApplicationStatus.referred    => AppColors.emeraldLight,
    ApplicationStatus.rejected    => AppColors.redLight,
    ApplicationStatus.hired       => AppColors.emeraldLight,
  };

  Color _statusFg(ApplicationStatus s) => switch (s) {
    ApplicationStatus.applied     => AppColors.textHint,
    ApplicationStatus.underReview => AppColors.info,
    ApplicationStatus.shortlisted => AppColors.primary,
    ApplicationStatus.referred    => AppColors.emerald,
    ApplicationStatus.rejected    => AppColors.red,
    ApplicationStatus.hired       => AppColors.emerald,
  };
}
