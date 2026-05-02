// lib/features/cv_job_matcher/presentation/screens/job_applicants_screen.dart
//
// PROVIDER screen — view all applicants for a posted job,
// ranked by intelligent match score (highest first).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/di/injection.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/applicants_cubit.dart';
import 'package:refsure/features/cv_job_matcher/presentation/screens/applicant_detail_screen.dart';
import 'package:refsure/features/cv_job_matcher/presentation/widgets/applicant_card.dart';

class JobApplicantsScreen extends StatelessWidget {
  const JobApplicantsScreen({super.key, required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ApplicantsCubit(repository: getIt<CvMatcherRepository>())
      ..watchJob(job.id),
    child: _JobApplicantsBody(job: job),
  );
}

class _JobApplicantsBody extends StatefulWidget {
  const _JobApplicantsBody({required this.job});
  final Job job;
  @override State<_JobApplicantsBody> createState() => _JobApplicantsBodyState();
}

class _JobApplicantsBodyState extends State<_JobApplicantsBody> {
  String _filter = 'all';

  static const _filters = [
    ('all',        'All'),
    ('applied',    'Applied'),
    ('shortlisted','Shortlisted'),
    ('referred',   'Referred'),
    ('rejected',   'Rejected'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.job.title),
        Text('${widget.job.company} · Applicants',
          style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w400)),
      ]),
    ),
    body: BlocBuilder<ApplicantsCubit, ApplicantsState>(
      builder: (ctx, state) {
        if (state is ApplicantsLoading) return const LoadingSpinner();
        if (state is ApplicantsError) return EmptyState(
          emoji: '⚠️', title: 'Error loading applicants', subtitle: state.message);

        if (state is ApplicantsLoaded) {
          final all = state.applications;
          final filtered = _filter == 'all' ? all
              : all.where((a) => a.status.name == _filter).toList();

          return Column(children: [
            // ── Summary strip ───────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _SummaryItem('${all.length}', 'Total', AppColors.textPrimary),
                _SummaryItem(
                  '${all.where((a) => a.matchScore >= 80).length}', '80%+ Match', AppColors.emerald),
                _SummaryItem(
                  '${all.where((a) => a.status == ApplicationStatus.shortlisted).length}',
                  'Shortlisted', AppColors.primary),
                _SummaryItem(
                  '${all.where((a) => a.status == ApplicationStatus.referred).length}',
                  'Referred ✅', AppColors.emerald),
              ])),

            // ── Filter chips ────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _filters.map((f) {
                  final on = _filter == f.$1;
                  final cnt = f.$1 == 'all' ? all.length
                      : all.where((a) => a.status.name == f.$1).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: on ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: on ? AppColors.primary : AppColors.border)),
                        child: Text('${f.$2} ($cnt)', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: on ? Colors.white : AppColors.textSecond)))));
                }).toList())),

            // ── List ────────────────────────────────────────
            Expanded(child: filtered.isEmpty
              ? EmptyState(
                  emoji: '📥',
                  title: _filter == 'all' ? 'No applicants yet'
                      : 'No ${_filter} applications',
                  subtitle: _filter == 'all'
                      ? 'Seekers who apply will appear here ranked by match score'
                      : 'Switch to All to see everyone')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    if (i == 0) return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${filtered.length} applicants · ranked by match score',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)));
                    final app = filtered[i - 1];
                    return ApplicantCard(
                      application: app,
                      rank: _filter == 'all' ? i : null,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ApplicantDetailScreen(
                          application: app, job: widget.job))));
                  })),
          ]);
        }

        return const LoadingSpinner();
      }),
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.value, this.label, this.color);
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.inter(
      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint)),
  ]);
}
