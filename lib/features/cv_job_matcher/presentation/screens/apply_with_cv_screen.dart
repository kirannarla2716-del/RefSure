// lib/features/cv_job_matcher/presentation/screens/apply_with_cv_screen.dart
//
// REQUESTER screen — paste or upload CV to apply for a job.
// Matching runs AUTOMATICALLY on submit. No manual matching required.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/di/injection.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_cubit.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_state.dart';
import 'package:refsure/providers/app_provider.dart';
import 'package:provider/provider.dart';

class ApplyWithCvScreen extends StatelessWidget {
  const ApplyWithCvScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CvMatcherCubit(repository: getIt<CvMatcherRepository>()),
    child: _ApplyBody(job: job),
  );
}

class _ApplyBody extends StatefulWidget {
  const _ApplyBody({required this.job});
  final Job job;
  @override State<_ApplyBody> createState() => _ApplyBodyState();
}

class _ApplyBodyState extends State<_ApplyBody> {
  final _cvCtrl = TextEditingController();

  @override
  void dispose() { _cvCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
    BlocListener<CvMatcherCubit, CvMatcherState>(
      listener: (ctx, state) {
        if (state is ApplicationSubmitted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => _ApplicationSuccessScreen(
              application: state.application,
              jobTitle: widget.job.title,
              company: widget.job.company,
            )));
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
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Apply for this Job'),
            Text('${widget.job.title} · ${widget.job.company}',
              style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w400)),
          ]),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Job summary ─────────────────────────────────
            SectionCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CompanyLogo(letter: widget.job.companyLogo, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.job.title, style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${widget.job.company} · ${widget.job.location}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond)),
                    const SizedBox(height: 4),
                    WorkModePill(widget.job.workMode),
                  ])),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 4, children:
                  widget.job.skills.take(5).map((s) => SkillChip(s, highlight: true)).toList()),
              ],
            )),

            const SizedBox(height: 12),

            // ── How it works ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('How this works', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                _Step('1', 'Paste your CV text below'),
                _Step('2', 'Tap Submit — our engine automatically matches your CV against this JD'),
                _Step('3', 'Provider sees your application ranked by intelligent match score'),
                _Step('4', 'Provider decides to shortlist, refer, or pass'),
              ])),

            const SizedBox(height: 16),

            // ── CV input ────────────────────────────────────
            Text('Paste Your CV / Resume', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Include your work experience, skills, education, '
                'certifications, and any relevant projects.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
            const SizedBox(height: 10),

            SectionCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _cvCtrl,
                maxLines: 16,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste your full CV text here...\n\n'
                      'Example:\nYour Name\nSoftware Engineer — 4 years experience\n\n'
                      'Skills: Python, Java, AWS, Docker, CI/CD...\n\n'
                      'Experience:\n  Company XYZ (2021–2024)\n  '
                      'Developed microservices on AWS, led a team of 3...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textHint))),
            ),

            const SizedBox(height: 6),

            // Character count
            Align(alignment: Alignment.centerRight,
              child: ListenableBuilder(
                listenable: _cvCtrl,
                builder: (_, __) => Text(
                  '${_cvCtrl.text.length} characters · '
                  '${_cvCtrl.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)))),

            const SizedBox(height: 20),

            // ── Submit ──────────────────────────────────────
            BlocBuilder<CvMatcherCubit, CvMatcherState>(
              builder: (ctx, state) {
                final loading = state is CvMatcherLoading;
                return ElevatedButton(
                  onPressed: loading ? null : () => _submit(ctx),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                  child: loading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Analysing your CV & submitting...'),
                        ])
                    : const Text('Submit Application'));
              }),

            const SizedBox(height: 8),
            Text('Your CV is matched automatically against the job requirements. '
                'You don\'t need to do anything else.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
              textAlign: TextAlign.center),

            const SizedBox(height: 24),
          ]),
      ),
    );

  Future<void> _submit(BuildContext ctx) async {
    final prov = context.read<AppProvider>();
    final user = prov.currentUser;
    if (user == null) return;

    await ctx.read<CvMatcherCubit>().submitApplication(
      job: widget.job,
      requesterId: user.id,
      requesterName: user.name,
      requesterEmail: user.email ?? '',
      resumeText: _cvCtrl.text,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);
  final String number, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 18, height: 18,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(number, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.inter(
        fontSize: 12, color: AppColors.textSecond))),
    ]));
}

// ── Success Screen ──────────────────────────────────────────

class _ApplicationSuccessScreen extends StatelessWidget {
  const _ApplicationSuccessScreen({
    required this.application,
    required this.jobTitle,
    required this.company,
  });
  final JobApplication application;
  final String jobTitle;
  final String company;

  @override
  Widget build(BuildContext context) {
    final match = application.matchResult;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Application Submitted!', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('$jobTitle at $company', style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSecond), textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // Match score reveal
          if (match != null) ...[
            SectionCard(child: Column(children: [
              Text('Your Match Score', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond)),
              const SizedBox(height: 12),
              MatchScoreRing(match.overallScore, size: 90),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.matchScoreColor(match.overallScore).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(match.roleLabel, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.matchScoreColor(match.overallScore)))),
              const SizedBox(height: 10),
              Text(match.providerSummary, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecond, height: 1.5),
                textAlign: TextAlign.center),
            ])),
          ],

          const Spacer(),

          ElevatedButton(
            onPressed: () {
              // Navigate back to home/jobs
              while (context.canPop()) context.pop();
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Back to Jobs')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/applications'),
            child: const Text('View My Applications')),
        ]),
      )));
  }

}
