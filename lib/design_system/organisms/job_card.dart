// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/router/route_names.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/models/match_report.dart';
import 'package:refsure/design_system/atoms/hot_badge.dart';
import 'package:refsure/design_system/atoms/info_row.dart';
import 'package:refsure/design_system/atoms/skill_chip.dart';
import 'package:refsure/design_system/atoms/tag_chip.dart';
import 'package:refsure/design_system/atoms/work_mode_pill.dart';
import 'package:refsure/design_system/molecules/company_logo.dart';
import 'package:refsure/design_system/molecules/match_band_pill.dart';
import 'package:refsure/design_system/molecules/match_score_ring.dart';
import 'package:refsure/design_system/organisms/section_card.dart';
import 'package:refsure/design_system/theme/app_colors.dart';
import 'package:refsure/providers/app_provider.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final MatchReport? matchReport;
  final bool showApplyButton;
  final bool compact;

  const JobCard(
      {super.key,
      required this.job,
      this.matchReport,
      this.showApplyButton = true,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final report = matchReport ??
        (prov.currentUser != null && prov.isSeeker
            ? prov.computeMatch(job)
            : null);
    final applied = prov.myApplications.any((a) => a.jobId == job.id);

    return SectionCard(
      onTap: () => context.push(RouteNames.jobDetailPath(job.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CompanyLogo(letter: job.companyLogo, size: 44),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(job.title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(job.company,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecond,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(job.department,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textHint)),
                      if (job.isHot) const HotBadge(),
                      if (job.isNew) ...[
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('NEW',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary))),
                      ],
                    ]),
              ])),
          if (report != null)
            MatchScoreRing(report.score, size: 48, showLabel: true),
        ]),

        const SizedBox(height: 10),

        // Meta
        Wrap(spacing: 12, runSpacing: 4, children: [
          InfoRow(Icons.location_on_outlined, job.location),
          WorkModePill(job.workMode),
          InfoRow(Icons.work_outline, '${job.minExp}\u2013${job.maxExp} yrs'),
          if (job.salaryMax > 0)
            InfoRow(Icons.currency_rupee,
                '${job.salaryMin}\u2013${job.salaryMax}L'),
        ]),

        const SizedBox(height: 8),

        // Skills
        Wrap(spacing: 6, runSpacing: 4, children: [
          ...job.skills.take(4).map((s) => SkillChip(s,
              matched: report?.matchedSkills
                      .map((m) => m.toLowerCase())
                      .contains(s.toLowerCase()) ??
                  false,
              compact: true)),
          if (job.skills.length > 4)
            Text('+${job.skills.length - 4}',
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
        ]),

        // Tags
        if (job.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
              spacing: 4,
              runSpacing: 4,
              children: job.tags.take(3).map((t) => TagChip(t)).toList()),
        ],

        // Match band
        if (report != null && prov.isSeeker) ...[
          const SizedBox(height: 8),
          MatchBandPill(band: report.band, label: report.bandLabel),
        ],

        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Footer
        LayoutBuilder(builder: (context, constraints) {
          final action = showApplyButton && prov.isSeeker
              ? applied
                  ? const _AppliedChip()
                  : _ApplyButton(job: job)
              : null;
          final details = Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.people_outline,
                  size: 13, color: AppColors.textHint),
              Text('${job.applicants} referral requests',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint)),
              Text('\u00B7 ${timeago.format(job.postedAt)}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint)),
            ],
          );
          if (constraints.maxWidth < 375 && action != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }
          return Row(children: [
            Expanded(child: details),
            if (action != null) ...[
              const SizedBox(width: 8),
              action,
            ],
          ]);
        }),
      ]),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip();

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.emeraldLight,
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check, size: 13, color: AppColors.emerald),
        const SizedBox(width: 4),
        Text('Referral requested',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald)),
      ]));
}

class _ApplyButton extends StatefulWidget {
  final Job job;
  const _ApplyButton({required this.job});
  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) => Semantics(
      label: _applying ? 'Requesting referral' : null,
      liveRegion: _applying,
      child: FilledButton(
          onPressed: _applying ? null : _apply,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
          child: _applying
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Request referral',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600))));

  Future<void> _apply() async {
    setState(() => _applying = true);
    dynamic result;
    try {
      result = await context.read<AppProvider>().applyToJob(widget.job);
    } on Object {
      result = 'error';
    } finally {
      if (mounted) setState(() => _applying = false);
    }
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final msgs = {
      true: (
        'Referral request sent. The referrer will review your profile.',
        AppColors.emerald,
      ),
      'already': (
        'You already requested a referral for this job.',
        AppColors.textSecond,
      ),
      'error': (
        provider.error ?? 'Could not request referral. Please try again.',
        AppColors.red,
      ),
    };
    final message =
        msgs[result] ?? ('Unexpected response. Please retry.', AppColors.red);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.$1),
        backgroundColor: message.$2,
        behavior: SnackBarBehavior.floating));
  }
}
