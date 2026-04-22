// lib/screens/main_screens.dart — v2.0
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import '../widgets/cards.dart';
import 'match_detail_screen.dart';

// ── Home Screen ────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    if (user == null) return const LoadingSpinner();

    final myApps   = prov.myApplications;
    final topJobs  = prov.filteredJobs.take(3).toList();
    final topProvs = prov.providers.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true, backgroundColor: Colors.white, surfaceTintColor: Colors.white,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hey ${user.name.split(' ').first} 👋', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text('Where real referrals happen', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textHint)),
          ]),
          actions: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                if (prov.unreadCount > 0) Positioned(right: 0, top: 0,
                  child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ])),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Padding(padding: const EdgeInsets.only(right: 16),
                child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 36))),
          ],
        ),

        SliverPadding(padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Search ─────────────────────────────────────
            GestureDetector(
              onTap: () => context.push('/jobs'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.search, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Search jobs, companies, skills...',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint)),
                ]))),
            const SizedBox(height: 14),

            // ── Org verify banner ──────────────────────────
            if (!user.orgVerified) ...[
              GestureDetector(
                onTap: () => context.push('/verify-org'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A66C2), Color(0xFF004182)]),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.verified_user_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Get Org Verified', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('3× more referral requests with verified badge',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ])),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                  ]))),
              const SizedBox(height: 14),
            ],

            // ── Stats ──────────────────────────────────────
            Row(children: [
              _statCard('${myApps.length}', 'Applied', AppColors.primary),
              const SizedBox(width: 8),
              _statCard(
                '${myApps.where((a) => a.status == AppStatus.referred).length}',
                'Referred ✅', AppColors.emerald),
              const SizedBox(width: 8),
              _statCard(
                '${myApps.where((a) => a.status == AppStatus.interview).length}',
                'Interview 📅', AppColors.accent),
            ]),
            const SizedBox(height: 20),

            // ── Recent applications ────────────────────────
            if (myApps.isNotEmpty) ...[
              SectionHeader(
                title: 'My Applications',
                action: TextButton(onPressed: () => context.push('/applications'),
                  child: const Text('View all'))),
              const SizedBox(height: 10),
              ...myApps.take(2).map((app) {
                final job = prov.findJob(app.jobId);
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: ApplicationCard(app: app, job: job));
              }),
              const SizedBox(height: 20),
            ],

            // ── Hot jobs ───────────────────────────────────
            SectionHeader(
              title: '🔥 Hot Jobs',
              action: TextButton(onPressed: () => context.push('/jobs'),
                child: const Text('See all'))),
            const SizedBox(height: 10),
            ...topJobs.map((j) => Padding(
              padding: const EdgeInsets.only(bottom: 12), child: JobCard(job: j))),
            const SizedBox(height: 20),

            // ── Top providers ──────────────────────────────
            SectionHeader(
              title: '⭐ Top Providers',
              action: TextButton(onPressed: () => context.push('/providers'),
                child: const Text('See all'))),
            const SizedBox(height: 10),
            ...topProvs.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProviderCard(provider: p))),
            const SizedBox(height: 16),
          ])),
        ),
      ]),
    );
  }

  Widget _statCard(String val, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Text(val, style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
          textAlign: TextAlign.center),
      ])));
}

// ── Jobs Screen ─────────────────────────────────────────────────
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _q = TextEditingController();

  @override
  void dispose() { _q.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final filter = prov.jobFilter;
    final jobs = prov.filteredJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          // Filter badge
          Stack(children: [
            IconButton(
              onPressed: () => _showFilterSheet(context),
              icon: const Icon(Icons.tune)),
            if (filter.isActive) Positioned(right: 8, top: 8,
              child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle))),
          ]),
        ],
      ),
      body: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16,8,16,10),
          child: TextField(controller: _q, onChanged: (v) {
              prov.updateJobFilter(prov.jobFilter.copyWith(query: v));
            },
            decoration: InputDecoration(
              hintText: 'Search jobs, skills, companies...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _q.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear),
                  onPressed: () { _q.clear(); prov.updateJobFilter(prov.jobFilter.copyWith(query: '')); }) : null))),
        // ── Quick filter chips ─────────────────────────────
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              _QuickChip('⭐ Best Match', filter.sortBy == JobSortBy.matchScore,
                () => prov.updateJobFilter(filter.copyWith(sortBy: JobSortBy.matchScore))),
              _QuickChip('🕐 Recent', filter.sortBy == JobSortBy.recent,
                () => prov.updateJobFilter(filter.copyWith(sortBy: JobSortBy.recent))),
              _QuickChip('🔥 Hot', filter.hotOnly,
                () => prov.updateJobFilter(filter.copyWith(hotOnly: !filter.hotOnly))),
              _QuickChip('🆕 Today', filter.todayOnly,
                () => prov.updateJobFilter(filter.copyWith(todayOnly: !filter.todayOnly))),
              _QuickChip('📅 Last 10 days', filter.last10Days,
                () => prov.updateJobFilter(filter.copyWith(last10Days: !filter.last10Days))),
              ...['Remote','Hybrid','On-site'].map((m) =>
                _QuickChip(m, filter.workMode == m, () =>
                  prov.updateJobFilter(filter.copyWith(
                    workMode: filter.workMode == m ? null : m)))),
              if (filter.isActive) ActionChip(
                label: Text('Clear all (${filter.activeCount})',
                  style: GoogleFonts.inter(fontSize: 12)),
                backgroundColor: AppColors.primaryLight,
                labelStyle: const TextStyle(color: AppColors.primary),
                onPressed: prov.clearJobFilter),
            ]))),

        Expanded(child: jobs.isEmpty
          ? EmptyState(emoji: '🔍', title: 'No jobs found',
              subtitle: 'Try different filters or clear all',
              action: TextButton(onPressed: prov.clearJobFilter,
                child: const Text('Clear filters')))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                if (i == 0) return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${jobs.length} jobs', style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textHint)));
                return JobCard(job: jobs[i - 1]);
              })),
      ]),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => const _FilterSheet());
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QuickChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: selected ? Colors.white : AppColors.textSecond))));
}

// ── Filter Bottom Sheet ────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _loc;
  RangeValues _exp = const RangeValues(0, 25);

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final filter = prov.jobFilter;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Advanced Filters', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(onPressed: () { prov.clearJobFilter(); Navigator.pop(context); },
            child: const Text('Reset all')),
        ]),
        const SizedBox(height: 16),

        TextField(
          onChanged: (v) => setState(() => _loc = v),
          decoration: const InputDecoration(
            labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 14),

        Text('Experience Range: ${_exp.start.round()}–${_exp.end.round()} yrs',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        RangeSlider(
          values: _exp, min: 0, max: 25, divisions: 25,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _exp = v)),

        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            prov.updateJobFilter(filter.copyWith(
              location: _loc?.isEmpty == true ? null : _loc,
              minExp: _exp.start.round(),
              maxExp: _exp.end.round()));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Apply Filters')),
      ]));
  }
}

// ── Job Detail Screen ──────────────────────────────────────────
class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final job      = prov.findJob(jobId);
    if (job == null) return const Scaffold(body: Center(child: Text('Job not found')));

    final user     = prov.currentUser;
    final report   = user != null && prov.isSeeker ? prov.computeMatch(job) : null;
    final myApp    = prov.myApplications.firstWhere(
      (a) => a.jobId == jobId, orElse: () =>
        Application(id: '', jobId: '', seekerId: '', providerId: '', matchScore: 0));
    final provider = prov.findUser(job.providerId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(job.company), actions: [
        if (report != null) Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchDetailScreen(
                report: report, jobTitle: job.title, company: job.company,
                seekerName: user?.name))),
            child: const Text('Full Analysis'))),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Job header card
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CompanyLogo(letter: job.companyLogo, size: 52),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${job.company} · ${job.department}', style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecond, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                WorkModePill(job.workMode),
                if (job.isHot) ...[const SizedBox(width: 8), const HotBadge()],
                if (job.isNew) ...[const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4)),
                    child: Text('NEW', style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary)))],
              ]),
            ])),
            if (report != null) MatchScoreRing(report.score, size: 56),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 6, children: [
            InfoRow(Icons.location_on_outlined, job.location),
            InfoRow(Icons.work_outline, '${job.minExp}–${job.maxExp} yrs'),
            if (job.salaryMax > 0) InfoRow(Icons.currency_rupee,
              '${job.salaryMin}–${job.salaryMax}L'),
            InfoRow(Icons.people_outline, '${job.applicants} applied'),
            InfoRow(Icons.calendar_today, 'Deadline: ${job.deadline}'),
          ]),
          if (job.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4,
              children: job.tags.map((t) => TagChip(t)).toList()),
          ],
        ])),

        // Match report card
        if (report != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchDetailScreen(
                report: report, jobTitle: job.title,
                company: job.company, seekerName: user?.name))),
            child: SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Match Analysis', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                MatchBandPill(band: report.band, label: report.bandLabel),
              ]),
              const SizedBox(height: 12),
              if (report.matchedSkills.isNotEmpty) ...[
                Text('✅ Matched: ${report.matchedSkills.take(3).join(", ")}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
              ],
              if (report.missingSkills.isNotEmpty)
                Text('⚠️ Missing: ${report.missingSkills.take(2).join(", ")}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber,
                    fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Tap to see full analysis →', style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.primary)),
            ])),
          ),
        ],

        const SizedBox(height: 12),

        // Description
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About this role', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(job.description, style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSecond, height: 1.6)),
        ])),

        const SizedBox(height: 12),

        // Skills
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Required Skills', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: job.skills.map((s) =>
            SkillChip(s, highlight: true,
              matched: report?.matchedSkills.map((m) => m.toLowerCase())
                  .contains(s.toLowerCase()) ?? false)).toList()),
          if (job.preferredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Preferred', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: job.preferredSkills.map((s) => SkillChip(s)).toList()),
          ],
        ])),

        // Provider card
        if (provider != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            onTap: () => context.push('/providers/${provider.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Posted by', style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(provider.name, style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                    if (provider.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
                  ]),
                  Text('${provider.title} · ${provider.company ?? ""}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
                ])),
                Column(children: [
                  Text('${provider.referralsMade}', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text('Referrals', style: GoogleFonts.inter(
                    fontSize: 9, color: AppColors.textHint)),
                ]),
              ]),
              if (provider.orgVerified) ...[
                const SizedBox(height: 8),
                OrgBadge(company: provider.company),
              ],
            ])),
        ],

        const SizedBox(height: 80),
      ]),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border))),
          child: myApp.id.isNotEmpty
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Text('Applied · ${myApp.statusLabel}', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emerald)),
                ])
              : Row(children: [
                  if (provider != null)
                    Expanded(child: OutlinedButton(
                      onPressed: () => context.push('/messages/${provider.id}'),
                      child: const Text('Message'))),
                  if (provider != null) const SizedBox(width: 12),
                  Expanded(flex: 2, child: _FullApplyButton(job: job, report: report)),
                ]),
        ),
      ),
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
      color: _bg.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _bg.withOpacity(0.2))),
    alignment: Alignment.center,
    child: Text(letter.toUpperCase(), style: GoogleFonts.inter(
      fontSize: size * 0.45, fontWeight: FontWeight.w900, color: _bg)));
}

class _FullApplyButton extends StatefulWidget {
  final Job job;
  final MatchReport? report;
  const _FullApplyButton({required this.job, this.report});
  @override
  State<_FullApplyButton> createState() => _FullApplyButtonState();
}

class _FullApplyButtonState extends State<_FullApplyButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _loading ? null : _apply,
    child: _loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(widget.report != null
            ? 'Apply · ${widget.report!.score}% match' : 'Apply Now'));

  Future<void> _apply() async {
    setState(() => _loading = true);
    final r = await context.read<AppProvider>().applyToJob(widget.job);
    if (!mounted) return;
    setState(() => _loading = false);
    final msgs = {
      true:         ('✅ Applied! Provider will be notified.', AppColors.emerald),
      'already':    ('Already applied to this job.', AppColors.textSecond),
      'low_match':  ('Match score < 40%. Update your profile.', AppColors.amber),
    };
    final m = msgs[r] ?? ('Error. Try again.', AppColors.red);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m.$1), backgroundColor: m.$2, behavior: SnackBarBehavior.floating));
  }
}

// ── Providers Screen ────────────────────────────────────────────
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});
  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final _q   = TextEditingController();
  bool _verifiedOnly = false;
  bool _orgVerifiedOnly = false;
  String _sortBy = 'trust';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    var providers = prov.providers.where((p) {
      if (_q.text.isNotEmpty) {
        final q = _q.text.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
               (p.company?.toLowerCase().contains(q) ?? false) ||
               p.skills.any((s) => s.toLowerCase().contains(q)) ||
               p.location.toLowerCase().contains(q);
      }
      return true;
    }).where((p) => !_verifiedOnly || p.verified)
      .where((p) => !_orgVerifiedOnly || p.orgVerified)
      .toList();

    providers.sort((a, b) => switch (_sortBy) {
      'trust'   => b.computedTrustScore.compareTo(a.computedTrustScore),
      'referrals' => b.referralsMade.compareTo(a.referralsMade),
      'response'  => a.avgResponseHours.compareTo(b.avgResponseHours),
      _           => b.computedTrustScore.compareTo(a.computedTrustScore),
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Referral Providers')),
      body: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16,8,16,10),
          child: TextField(controller: _q, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by name, company, skill, location...',
              prefixIcon: Icon(Icons.search, color: AppColors.primary)))),
        // Filter/sort bar
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _QuickChip('✅ Verified', _verifiedOnly,
                () => setState(() => _verifiedOnly = !_verifiedOnly)),
              _QuickChip('🏢 Org Verified', _orgVerifiedOnly,
                () => setState(() => _orgVerifiedOnly = !_orgVerifiedOnly)),
              _QuickChip('⭐ Trust', _sortBy == 'trust',
                () => setState(() => _sortBy = 'trust')),
              _QuickChip('🏆 Most Referrals', _sortBy == 'referrals',
                () => setState(() => _sortBy = 'referrals')),
              _QuickChip('⚡ Fastest Response', _sortBy == 'response',
                () => setState(() => _sortBy = 'response')),
            ]))),

        Expanded(child: providers.isEmpty
          ? const EmptyState(emoji: '👥', title: 'No providers found',
              subtitle: 'Try different filters')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => ProviderCard(provider: providers[i]))),
      ]),
    );
  }
}

// ── Provider Detail ─────────────────────────────────────────────
class ProviderDetailScreen extends StatelessWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final provider = prov.findUser(providerId);
    if (provider == null) return const Scaffold(body: Center(child: Text('Not found')));
    final jobs = prov.activeJobs.where((j) => j.providerId == providerId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(provider.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Profile header
        SectionCard(child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 64),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(provider.name, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800))),
                if (provider.verified) ...[const SizedBox(width: 8), const VerifiedBadge()],
              ]),
              Text(provider.headline, style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond)),
              if (provider.company != null)
                Text(provider.company!, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (provider.badge != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLight, borderRadius: BorderRadius.circular(20)),
                child: Text('${provider.badge!.emoji} ${provider.badge!.label} Referrer',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.gold))),
            ])),
          ]),
          if (provider.orgVerified) ...[
            const SizedBox(height: 10),
            OrgBadge(company: provider.company),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Stats grid
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            StatBox(label: 'Referrals', value: '${provider.referralsMade}',
              valueColor: AppColors.primary),
            StatBox(label: 'Successful', value: '${provider.successfulReferrals}',
              valueColor: AppColors.emerald),
            StatBox(label: 'Success %', value: '${provider.successRate}%'),
            StatBox(label: 'Jobs Posted', value: '${provider.totalJobsPosted}'),
          ]),
          const SizedBox(height: 14),
          TrustScoreBar(provider.computedTrustScore),
          const SizedBox(height: 10),
          ProfileCompletenessBar(provider.profileComplete),
        ])),

        const SizedBox(height: 12),

        // Bio
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(provider.bio.isEmpty ? 'No bio provided.' : provider.bio,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond, height: 1.6)),
        ])),

        const SizedBox(height: 12),

        // Skills
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Skills & Expertise', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6,
            children: provider.skills.map((s) => SkillChip(s)).toList()),
        ])),

        // Active jobs
        if (jobs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Active Openings (${jobs.length})', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...jobs.map((j) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: JobCard(job: j))),
        ],

        const SizedBox(height: 80),
      ]),

      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/messages/$providerId'),
            icon: const Icon(Icons.message_outlined),
            label: Text('Message ${provider.name.split(' ').first}')))),
    );
  }
}

// ── Notifications ───────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final notifs = prov.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'),
        actions: [
          if (prov.unreadCount > 0)
            TextButton(onPressed: prov.markAllNotifsRead, child: const Text('Mark all read')),
        ]),
      body: notifs.isEmpty
          ? const EmptyState(emoji: '🔔', title: 'No notifications yet',
              subtitle: 'Referral updates, application status changes will appear here')
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = notifs[i];
                const icons = {
                  'application': '📋', 'status': '🔔',
                  'message': '💬', 'referral': '✅', 'match': '🎯'};
                return GestureDetector(
                  onTap: () {
                    prov.markNotifRead(n.id);
                    if (n.actionRoute != null) context.push(n.actionRoute!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.read ? Colors.white : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: n.read ? AppColors.border : AppColors.primary.withOpacity(0.2))),
                    child: Row(children: [
                      Text(icons[n.type] ?? '🔔', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.text, style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(timeago.format(n.createdAt), style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint)),
                      ])),
                      if (!n.read) Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
                    ])));
              }),
    );
  }
}

// ── Org Verify Screen ───────────────────────────────────────────
class OrgVerifyScreen extends StatefulWidget {
  const OrgVerifyScreen({super.key});
  @override
  State<OrgVerifyScreen> createState() => _OrgVerifyScreenState();
}

class _OrgVerifyScreenState extends State<OrgVerifyScreen> {
  final _email = TextEditingController();
  final _otp   = TextEditingController();
  bool _otpSent = false, _sending = false, _verifying = false;
  String? _error, _success;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify Organisation')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏢', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Get Org Verified', style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800)),
        Text('Enter your work email to receive a verification code.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
        const SizedBox(height: 24),

        TextField(controller: _email, enabled: !_otpSent,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Work Email',
            hintText: 'yourname@company.com',
            prefixIcon: Icon(Icons.business_outlined))),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.red)),
        ],

        const SizedBox(height: 16),

        if (!_otpSent) ElevatedButton(
          onPressed: _sending ? null : _send,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _sending
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send Verification Code')),

        if (_otpSent) ...[
          const SizedBox(height: 16),
          TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700,
              letterSpacing: 10),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Verification Code', counterText: '',
              helperText: 'Code sent to ${_email.text}')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _verifying ? null : _verify,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _verifying
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Get Badge')),
        ],

        if (_success != null) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.verified, color: AppColors.emerald, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(_success!, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emerald))),
            ])),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Back to Profile')),
        ],
      ])),
  );

  Future<void> _send() async {
    setState(() { _sending = true; _error = null; });
    final r = await context.read<AppProvider>().sendOrgEmailOtp(_email.text.trim());
    setState(() { _sending = false; });
    if (r.success) setState(() => _otpSent = true);
    else setState(() => _error = r.error);
  }

  Future<void> _verify() async {
    setState(() { _verifying = true; _error = null; });
    final r = await context.read<AppProvider>()
        .verifyOrgEmailOtp(_email.text.trim(), _otp.text.trim());
    setState(() => _verifying = false);
    if (r.success) setState(() => _success = '${r.companyName ?? "Organisation"} verified! 🎉 Your profile now shows the Org Verified badge.');
    else setState(() => _error = r.error);
  }
}
