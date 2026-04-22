// lib/widgets/cards.dart — v2.0
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import 'common.dart';

// ── JobCard ────────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final Job job;
  final MatchReport? matchReport;
  final bool showApplyButton;
  final bool compact;

  const JobCard({super.key, required this.job,
    this.matchReport, this.showApplyButton = true, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final report = matchReport ?? (prov.currentUser != null && prov.isSeeker
        ? prov.computeMatch(job) : null);
    final applied = prov.myApplications.any((a) => a.jobId == job.id);

    return SectionCard(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CompanyLogo(letter: job.companyLogo, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(job.company, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(children: [
              Text(job.department, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textHint)),
              if (job.isHot) ...[const SizedBox(width: 8), const HotBadge()],
              if (job.isNew) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                  child: Text('NEW', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary))),
              ],
            ]),
          ])),
          if (report != null) MatchScoreRing(report.score, size: 48, showLabel: true),
        ]),

        const SizedBox(height: 10),

        // ── Meta ──────────────────────────────────────────
        Wrap(spacing: 12, runSpacing: 4, children: [
          InfoRow(Icons.location_on_outlined, job.location),
          WorkModePill(job.workMode),
          InfoRow(Icons.work_outline, '${job.minExp}–${job.maxExp} yrs'),
          if (job.salaryMax > 0)
            InfoRow(Icons.currency_rupee, '${job.salaryMin}–${job.salaryMax}L'),
        ]),

        const SizedBox(height: 8),

        // ── Skills ────────────────────────────────────────
        Wrap(spacing: 6, runSpacing: 4, children: [
          ...job.skills.take(4).map((s) => SkillChip(s,
            matched: report?.matchedSkills.map((m) => m.toLowerCase())
                .contains(s.toLowerCase()) ?? false, compact: true)),
          if (job.skills.length > 4) Text('+${job.skills.length - 4}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
        ]),

        // ── Tags ──────────────────────────────────────────
        if (job.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4,
            children: job.tags.take(3).map((t) => TagChip(t)).toList()),
        ],

        // ── Match band ────────────────────────────────────
        if (report != null && prov.isSeeker) ...[
          const SizedBox(height: 8),
          MatchBandPill(band: report.band, label: report.bandLabel),
        ],

        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // ── Footer ────────────────────────────────────────
        Row(children: [
          Icon(Icons.people_outline, size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text('${job.applicants} applied', style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textHint)),
          const SizedBox(width: 8),
          Text('· ${timeago.format(job.postedAt)}', style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textHint)),
          const Spacer(),
          if (showApplyButton && prov.isSeeker)
            applied ? _AppliedChip() : _ApplyButton(job: job),
        ]),
      ]),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String letter;
  final double size;
  const _CompanyLogo({required this.letter, required this.size});

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

class _AppliedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check, size: 13, color: AppColors.emerald),
      const SizedBox(width: 4),
      Text('Applied', style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emerald)),
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
  Widget build(BuildContext context) => FilledButton(
    onPressed: _applying ? null : _apply,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    child: _applying
        ? const SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text('Apply', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600)));

  Future<void> _apply() async {
    setState(() => _applying = true);
    final r = await context.read<AppProvider>().applyToJob(widget.job);
    if (!mounted) return;
    setState(() => _applying = false);
    final msgs = {
      true:         ('✅ Applied! Provider will review your profile.', AppColors.emerald),
      'already':    ('Already applied to this job.', AppColors.textSecond),
      'low_match':  ('Match score too low (< 40%). Update your profile to qualify.', AppColors.amber),
      'error':      ('Something went wrong. Try again.', AppColors.red),
    };
    final m = msgs[r] ?? ('Unexpected result.', AppColors.textSecond);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m.$1), backgroundColor: m.$2,
      behavior: SnackBarBehavior.floating));
  }
}

// ── ProviderCard ───────────────────────────────────────────────
class ProviderCard extends StatelessWidget {
  final AppUser provider;
  const ProviderCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: () => context.push('/providers/${provider.id}'),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 48),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(provider.name, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (provider.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
          ]),
          Text(provider.title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (provider.company != null)
            Text(provider.company!, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ])),
        if (provider.badge != null) _BadgePill(provider.badge!),
      ]),

      // Org verified
      if (provider.orgVerified) ...[
        const SizedBox(height: 8),
        OrgBadge(company: provider.company),
      ],

      const SizedBox(height: 10),
      if (provider.bio.isNotEmpty)
        Text(provider.bio, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 10),

      Wrap(spacing: 6, runSpacing: 4, children: [
        ...provider.skills.take(3).map((s) => SkillChip(s, compact: true)),
        if (provider.skills.length > 3) Text('+${provider.skills.length - 3}',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
      ]),

      const SizedBox(height: 10),
      TrustScoreBar(provider.computedTrustScore),
      const SizedBox(height: 10),
      const Divider(height: 1),
      const SizedBox(height: 8),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _StatItem('✅', '${provider.referralsMade}', 'Referrals'),
        _StatItem('🎯', '${provider.successRate}%', 'Success'),
        _StatItem('⚡', provider.responseTime, 'Response'),
        _StatItem('📋', '${provider.totalJobsPosted}', 'Jobs'),
      ]),
    ]),
  );
}

class _StatItem extends StatelessWidget {
  final String emoji, value, label;
  const _StatItem(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 11)),
      const SizedBox(width: 3),
      Text(value, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),
    Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint)),
  ]);
}

class _BadgePill extends StatelessWidget {
  final ReferralBadge badge;
  const _BadgePill(this.badge);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.goldLight, borderRadius: BorderRadius.circular(20)),
    child: Text('${badge.emoji} ${badge.label}', style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold)));
}

// ── ApplicationCard (seeker view) ─────────────────────────────
class ApplicationCard extends StatelessWidget {
  final Application app;
  final Job? job;
  const ApplicationCard({super.key, required this.app, this.job});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: job != null ? () => context.push('/jobs/${job!.id}') : null,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (job != null) ...[
          _CompanyLogo(letter: job!.companyLogo, size: 40),
          const SizedBox(width: 12),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job?.title ?? 'Unknown Job', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700)),
          if (job != null)
            Text('${job!.company} · ${job!.location}', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond)),
        ])),
        if (app.matchReport != null)
          MatchScoreRing(app.matchScore, size: 44),
      ]),

      const SizedBox(height: 10),

      Row(children: [
        StatusPill(status: app.statusKey, label: app.statusLabel),
        const Spacer(),
        Text(timeago.format(app.appliedAt), style: GoogleFonts.inter(
          fontSize: 11, color: AppColors.textHint)),
      ]),

      if (app.matchReport != null) ...[
        const SizedBox(height: 8),
        MatchBandPill(band: app.matchReport!.band, label: app.matchReport!.bandLabel),
      ],

      if (app.providerNote != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.format_quote, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(app.providerNote!, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond, fontStyle: FontStyle.italic))),
          ])),
      ],
    ]),
  );
}
