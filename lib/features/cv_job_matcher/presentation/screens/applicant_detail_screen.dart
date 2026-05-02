// lib/features/cv_job_matcher/presentation/screens/applicant_detail_screen.dart
//
// PROVIDER screen — full intelligent match analysis for one applicant.
// Provider can shortlist, refer, reject, or add a note.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/di/injection.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_cubit.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_state.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/recommendation_badge.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/score_breakdown_card.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/skills_section.dart';

class ApplicantDetailScreen extends StatelessWidget {
  const ApplicantDetailScreen({
    super.key,
    required this.application,
    required this.job,
  });

  final JobApplication application;
  final Job job;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CvMatcherCubit(repository: getIt<CvMatcherRepository>()),
    child: _ApplicantDetailBody(application: application, job: job),
  );
}

class _ApplicantDetailBody extends StatefulWidget {
  const _ApplicantDetailBody({required this.application, required this.job});
  final JobApplication application;
  final Job job;
  @override State<_ApplicantDetailBody> createState() => _ApplicantDetailBodyState();
}

class _ApplicantDetailBodyState extends State<_ApplicantDetailBody> {
  late ApplicationStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.application.status;
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.application.matchResult;

    return BlocListener<CvMatcherCubit, CvMatcherState>(
      listener: (ctx, state) {
        if (state is DecisionSaved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Decision saved'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating));
        }
        if (state is CvMatcherError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(widget.application.requesterName),
          actions: [
            if (match != null)
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy provider summary',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: match.providerSummary));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Summary copied'),
                    behavior: SnackBarBehavior.floating));
                }),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Candidate header ─────────────────────────────
            SectionCard(child: Row(children: [
              UserAvatar(name: widget.application.requesterName, size: 56),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.application.requesterName, style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800)),
                Text(widget.application.requesterEmail, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecond)),
                const SizedBox(height: 6),
                _StatusDropdown(
                  current: _status,
                  onChanged: (newStatus) {
                    setState(() => _status = newStatus);
                    _saveDecision(context, newStatus);
                  }),
              ])),
              if (match != null) MatchScoreRing(match.overallScore, size: 60),
            ])),

            const SizedBox(height: 12),

            // ── No match result (shouldn't happen, but safe) ─
            if (match == null)
              const SectionCard(child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Match analysis not available for this application.'))),

            // ── Match result ─────────────────────────────────
            if (match != null) ...[

              // Hero score + recommendation
              SectionCard(child: Column(children: [
                MatchScoreRing(match.overallScore, size: 100),
                const SizedBox(height: 12),
                RecommendationBadge(recommendation: match.recommendation, large: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Detected as ', style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecond)),
                    Text(match.roleLabel, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                  ])),
              ])),

              const SizedBox(height: 12),

              // Provider summary
              SectionCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.summarize_outlined, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Match Summary', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  Text(match.providerSummary, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecond, height: 1.6)),
                ])),

              const SizedBox(height: 12),

              // Role understanding
              SectionCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role Understanding', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(match.roleUnderstandingSummary, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecond, height: 1.6)),
                ])),

              const SizedBox(height: 12),

              // Score breakdown
              ScoreBreakdownCard(result: match),

              const SizedBox(height: 12),

              // Skills
              SectionCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skills Analysis', style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  SkillsSection(
                    title: 'Matched Skills',
                    skills: match.matchedSkills,
                    matched: true),
                  if (match.missingSkills.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SkillsSection(
                      title: 'Missing Skills',
                      skills: match.missingSkills,
                      matched: false),
                  ],
                ])),

              const SizedBox(height: 12),

              // Match indicators
              SectionCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Match Indicators', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _Indicator('Experience Match', match.experienceMatch),
                  const SizedBox(height: 6),
                  _Indicator('Domain Match', match.domainMatch),
                  const SizedBox(height: 6),
                  _Indicator('Tools & Technology Match', match.toolsMatch),
                ])),

              const SizedBox(height: 12),

              // Strong areas
              if (match.strongAreas.isNotEmpty) SectionCard(
                child: BulletList(
                  title: 'Strong Fit Areas',
                  items: match.strongAreas,
                  icon: Icons.star_outline,
                  iconColor: AppColors.emerald)),

              if (match.strongAreas.isNotEmpty) const SizedBox(height: 12),

              // Weak areas
              if (match.weakAreas.isNotEmpty) SectionCard(
                child: BulletList(
                  title: 'Areas of Concern',
                  items: match.weakAreas,
                  icon: Icons.warning_amber_outlined,
                  iconColor: AppColors.amber)),

              if (match.weakAreas.isNotEmpty) const SizedBox(height: 12),

              // Candidate suggestions
              SectionCard(child: BulletList(
                title: 'Suggestions for Candidate',
                items: match.candidateSuggestions,
                icon: Icons.lightbulb_outline,
                iconColor: AppColors.primary)),

              const SizedBox(height: 12),

              // Provider note
              _ProviderNoteCard(
                applicationId: widget.application.id,
                existingNote: widget.application.providerNote,
                status: _status,
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),

        // ── Action bar ──────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              _ActionBtn('Reject',    AppColors.redLight,     AppColors.red,
                () => _confirm(context, ApplicationStatus.rejected, 'Reject this candidate?')),
              const SizedBox(width: 8),
              _ActionBtn('Shortlist', AppColors.primaryLight, AppColors.primary,
                () => _updateStatus(context, ApplicationStatus.shortlisted)),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: () => _confirm(context, ApplicationStatus.referred,
                  'Refer this candidate for ${widget.job.title}?'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('✅ Refer Candidate'))),
            ])),
        ),
      ),
    );
  }

  void _updateStatus(BuildContext ctx, ApplicationStatus status) {
    setState(() => _status = status);
    _saveDecision(ctx, status);
  }

  void _saveDecision(BuildContext ctx, ApplicationStatus status) {
    ctx.read<CvMatcherCubit>().updateDecision(
      applicationId: widget.application.id,
      status: status);
  }

  void _confirm(BuildContext ctx, ApplicationStatus status, String message) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            _updateStatus(ctx, status);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: status == ApplicationStatus.rejected
                ? AppColors.red : AppColors.emerald),
          child: const Text('Confirm')),
      ]));
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.current, required this.onChanged});
  final ApplicationStatus current;
  final ValueChanged<ApplicationStatus> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<ApplicationStatus>(
      value: current,
      isDense: true,
      items: ApplicationStatus.values.map((s) => DropdownMenuItem(
        value: s,
        child: Text(_label(s), style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); }));

  String _label(ApplicationStatus s) => switch (s) {
    ApplicationStatus.applied     => 'Applied',
    ApplicationStatus.underReview => 'Under Review',
    ApplicationStatus.shortlisted => 'Shortlisted',
    ApplicationStatus.referred    => 'Referred',
    ApplicationStatus.rejected    => 'Rejected',
    ApplicationStatus.hired       => 'Hired',
  };
}

class _Indicator extends StatelessWidget {
  const _Indicator(this.label, this.matched);
  final String label;
  final bool matched;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(matched ? Icons.check_circle : Icons.cancel_outlined,
      size: 18, color: matched ? AppColors.emerald : AppColors.red),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
  ]);
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(this.label, this.bg, this.fg, this.onTap);
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.3))),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: fg))));
}

// ── Provider note card ──────────────────────────────────────

class _ProviderNoteCard extends StatefulWidget {
  const _ProviderNoteCard({
    required this.applicationId,
    required this.existingNote,
    required this.status,
  });
  final String applicationId;
  final String? existingNote;
  final ApplicationStatus status;
  @override State<_ProviderNoteCard> createState() => _ProviderNoteCardState();
}

class _ProviderNoteCardState extends State<_ProviderNoteCard> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existingNote ?? '');
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Internal Note', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () {
            if (_editing) {
              // Save note
              context.read<CvMatcherCubit>().updateDecision(
                applicationId: widget.applicationId,
                status: widget.status,
                providerNote: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim());
            }
            setState(() => _editing = !_editing);
          },
          child: Text(_editing ? 'Save' : 'Edit')),
      ]),
      const SizedBox(height: 8),
      _editing
        ? TextField(controller: _ctrl, maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add private note about this candidate...'))
        : Text(_ctrl.text.isEmpty ? 'No note added yet.' : _ctrl.text,
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond,
              fontStyle: _ctrl.text.isEmpty ? FontStyle.italic : FontStyle.normal)),
    ]));
}
