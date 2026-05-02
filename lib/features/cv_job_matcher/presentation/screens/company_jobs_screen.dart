// lib/features/cv_job_matcher/presentation/screens/company_jobs_screen.dart
//
// PROVIDER screen — browse company job openings from the last 30 days
// and select which ones to post on the platform.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/di/injection.dart';
import 'package:refsure/design_system/design_system.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_opening.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_cubit.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_state.dart';
import 'package:refsure/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompanyJobsScreen extends StatelessWidget {
  const CompanyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CvMatcherCubit(repository: getIt<CvMatcherRepository>()),
    child: const _CompanyJobsBody(),
  );
}

class _CompanyJobsBody extends StatefulWidget {
  const _CompanyJobsBody();
  @override State<_CompanyJobsBody> createState() => _CompanyJobsBodyState();
}

class _CompanyJobsBodyState extends State<_CompanyJobsBody> {
  final _companyCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from provider profile
    final user = context.read<AppProvider>().currentUser;
    if (user != null) {
      _companyCtrl.text = user.company ?? '';
      _countryCtrl.text = user.location.isNotEmpty ? user.location : 'India';
      // Auto-fetch on open if company is known
      if (_companyCtrl.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
      }
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    BlocListener<CvMatcherCubit, CvMatcherState>(
      listener: (ctx, state) {
        if (state is JobPostedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Job posted! Seekers can now apply.'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating));
          _fetch(); // Refresh list to mark as posted
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
          title: const Text('Company Job Openings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetched ? _fetch : null,
              tooltip: 'Refresh'),
          ],
        ),
        body: Column(children: [

          // ── Filter bar ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  hintText: 'e.g. Microsoft',
                  prefixIcon: Icon(Icons.business_outlined),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ))),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country / Location',
                  hintText: 'e.g. India',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ))),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _fetch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Fetch')),
            ])),

          // ── Content ────────────────────────────────────────
          Expanded(child: BlocBuilder<CvMatcherCubit, CvMatcherState>(
            builder: (ctx, state) {
              if (state is CvMatcherLoading) {
                return _LoadingView(company: _companyCtrl.text);
              }
              if (state is CvMatcherError) {
                return EmptyState(
                  emoji: '⚠️',
                  title: 'Could not load jobs',
                  subtitle: state.message,
                  action: ElevatedButton(onPressed: _fetch, child: const Text('Retry')));
              }
              if (state is CompanyJobsLoaded) {
                if (state.jobs.isEmpty) {
                  return const EmptyState(
                    emoji: '🔍',
                    title: 'No open positions found',
                    subtitle: 'Try a different company name or location');
                }
                return _JobList(jobs: state.jobs);
              }
              return _InitialView(company: _companyCtrl.text);
            },
          )),
        ]),
      ),
    );

  void _fetch() {
    if (_companyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter your company name first'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _fetched = true);
    context.read<CvMatcherCubit>().fetchCompanyJobs(
      companyName: _companyCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty ? 'India' : _countryCtrl.text.trim(),
    );
  }
}

// ── Job list ────────────────────────────────────────────────

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});
  final List<JobOpening> jobs;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: jobs.length + 1,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (ctx, i) {
      if (i == 0) return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('${jobs.length} openings · last 30 days',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)));
      return _JobOpeningCard(job: jobs[i - 1]);
    });
}

class _JobOpeningCard extends StatefulWidget {
  const _JobOpeningCard({required this.job});
  final JobOpening job;
  @override State<_JobOpeningCard> createState() => _JobOpeningCardState();
}

class _JobOpeningCardState extends State<_JobOpeningCard> {
  bool _posting = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return SectionCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${job.companyName} · ${job.department}', style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              WorkModePill(job.workMode),
              InfoRow(Icons.location_on_outlined, job.location),
              InfoRow(Icons.work_outline, '${job.experienceMin}–${job.experienceMax} yrs'),
            ]),
          ])),
          if (job.postedDate != null) Text(
            timeago.format(job.postedDate!),
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
        ]),

        if (job.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children:
            job.requiredSkills.take(5).map((s) => SkillChip(s)).toList()),
        ],

        if (job.salaryRange.isNotEmpty) ...[
          const SizedBox(height: 6),
          InfoRow(Icons.currency_rupee, job.salaryRange),
        ],

        // Source badge
        if (job.sourceUrl != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.link, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('via ${job.sourcePlatform}', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textHint)),
          ]),
        ],

        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),

        // Actions
        job.isAlreadyPosted
          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text('Already posted on platform', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.emerald)),
            ])
          : Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _viewDetail(context, job),
                child: const Text('View Details'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: _posting ? null : () => _post(context, job),
                child: _posting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post on Platform'))),
            ]),
      ],
    ));
  }

  void _viewDetail(BuildContext context, JobOpening job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _JobDetailSheet(job: job));
  }

  Future<void> _post(BuildContext context, JobOpening job) async {
    setState(() => _posting = true);
    final prov = context.read<AppProvider>();
    if (prov.currentUser == null) return;

    // Convert JobOpening → platform Job and post it
    await prov.postJob({
      'title':          job.title,
      'department':     job.department,
      'location':       job.location,
      'workMode':       job.workMode,
      'description':    job.fullJdText,
      'skills':         job.requiredSkills,
      'preferredSkills':job.preferredSkills,
      'tags':           <String>[],
      'minExp':         job.experienceMin,
      'maxExp':         job.experienceMax,
      'isHot':          false,
      'deadline':       '2026-12-31',
      'externalUrl':    job.sourceUrl,
      'company':        job.companyName,
    });

    if (mounted) setState(() => _posting = false);
  }
}

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({required this.job});
  final JobOpening job;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (_, ctrl) => ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(job.title, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800)),
        Text('${job.companyName} · ${job.location} · ${job.workMode}',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond)),
        const SizedBox(height: 16),
        if (job.requiredSkills.isNotEmpty) ...[
          Text('Required Skills', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: job.requiredSkills.map((s) => SkillChip(s, highlight: true)).toList()),
          const SizedBox(height: 12),
        ],
        if (job.responsibilities.isNotEmpty) ...[
          Text('Responsibilities', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...job.responsibilities.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: AppColors.primary)),
              Expanded(child: Text(r, style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond))),
            ]))),
        ],
        const SizedBox(height: 12),
        Text('Job Description', style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(job.description, style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textSecond, height: 1.6)),
      ],
    ));
}

class _InitialView extends StatelessWidget {
  const _InitialView({required this.company});
  final String company;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('🏢', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text(company.isEmpty ? 'Enter your company name and tap Fetch'
          : 'Tap Fetch to load $company openings',
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecond),
        textAlign: TextAlign.center),
    ]));
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.company});
  final String company;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 16),
      Text('Fetching ${company.isEmpty ? "jobs" : "$company jobs"}...',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
      const SizedBox(height: 6),
      Text('Last 30 days · ranked by recency',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
    ]));
}
