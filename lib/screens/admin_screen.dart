import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/models/admin_user.dart';
import '../core/models/app_user.dart';
import '../core/models/feature_readiness.dart';
import '../core/models/safety_report.dart';
import '../core/utils/test_data_seeder.dart';
import '../providers/app_provider.dart';
import '../services/trusted_account_service.dart';
import '../services/trusted_safety_service.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _service = TrustedAccountService();
  final _safety = TrustedSafetyService();
  List<AdminUser> _users = const [];
  List<SafetyReport> _reports = const [];
  bool _loading = true;
  String? _error;
  FeatureReadiness _investorReadiness =
      const FeatureReadiness(featureName: 'Investor experience');

  bool get _demo => DemoModePolicy.isEnabled;

  @override
  void dispose() {
    _service.dispose();
    _safety.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demo && !_loading) {
      final provider = context.read<AppProvider>();
      final availableIds = <String>{
        if (provider.currentUser != null) provider.currentUser!.id,
        ...provider.providers.map((user) => user.id),
        ...provider.seekers.map((user) => user.id),
      };
      if (availableIds.length > _users.length) {
        _load();
        return;
      }
    }
    if (_users.isEmpty && _loading) _load();
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    if (_demo) {
      final source = <AppUser>[
        if (provider.currentUser != null) provider.currentUser!,
        ...provider.providers,
        ...provider.seekers,
      ];
      final unique = <String, AdminUser>{};
      for (final user in source) {
        unique[user.id] = AdminUser(
          id: user.id,
          name: user.name,
          email: user.email ?? 'Seeded demo account',
          role: user.role.name,
          disabled: false,
          additionalAccess: const [],
        );
      }
      // Direct deep links can arrive before demo profiles finish loading.
      // Keep waiting so the next provider notification retries this load.
      if (unique.isEmpty) return;
      if (mounted)
        setState(() {
          _users = unique.values.toList();
          _reports = [
            SafetyReport(
              id: 'seed_report_001',
              reporterId: provider.currentUser?.id ?? 'demo-user',
              targetId: 'seed_provider_001',
              category: 'fraud',
              details: 'Requested payment in exchange for a referral.',
              status: 'open',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              contextId: 'conversation:seed_provider_001',
            ),
          ];
          _loading = false;
        });
      return;
    }
    try {
      final results = await Future.wait([
        _service.listAdminUsers(),
        _safety.listReports(),
      ]);
      final users = results[0] as List<AdminUser>;
      final reports = results[1] as List<SafetyReport>;
      if (mounted)
        setState(() {
          _users = users;
          _reports = reports;
          _loading = false;
        });
    } on TrustedAccountException catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          _loading = false;
        });
    } on TrustedSafetyException catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          _loading = false;
        });
    } on Object {
      if (mounted)
        setState(() {
          _error = 'The administration workspace could not be loaded.';
          _loading = false;
        });
    }
  }

  Future<void> _reviewReport(SafetyReport report, String decision) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('${decision[0].toUpperCase()}${decision.substring(1)} report'),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Moderation note',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim().isNotEmpty),
            child: const Text('Confirm decision'),
          ),
        ],
      ),
    );
    final note = controller.text.trim();
    controller.dispose();
    if (confirmed != true || note.isEmpty) return;
    if (_demo) {
      setState(() => _reports =
          _reports.where((candidate) => candidate.id != report.id).toList());
      return;
    }
    try {
      await _safety.reviewReport(
        reportId: report.id,
        decision: decision,
        note: note,
      );
      await _load();
    } on TrustedSafetyException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _run(AdminUser user, String action) async {
    if (_demo) {
      setState(() {
        if (action == 'remove') {
          _users =
              _users.where((candidate) => candidate.id != user.id).toList();
        } else {
          _users = _users
              .map((candidate) => candidate.id == user.id
                  ? AdminUser(
                      id: candidate.id,
                      name: candidate.name,
                      email: candidate.email,
                      role: candidate.role,
                      disabled: action == 'deactivate'
                          ? true
                          : action == 'activate'
                              ? false
                              : candidate.disabled,
                      additionalAccess: candidate.additionalAccess,
                    )
                  : candidate)
              .toList();
        }
      });
      return;
    }
    try {
      await _service.updateAdminUser(userId: user.id, action: action);
      await _load();
    } on TrustedAccountException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _grantAccess(AdminUser user) async {
    final controller =
        TextEditingController(text: user.additionalAccess.join(', '));
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Additional access'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'support, jobs.review, beta.manage',
            helperText: 'Comma-separated scoped permissions',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save access')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final access = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (_demo) {
      setState(() => _users = _users
          .map((candidate) => candidate.id == user.id
              ? AdminUser(
                  id: candidate.id,
                  name: candidate.name,
                  email: candidate.email,
                  role: candidate.role,
                  disabled: candidate.disabled,
                  additionalAccess: access)
              : candidate)
          .toList());
      return;
    }
    await _service.updateAdminUser(
        userId: user.id, action: 'grantAccess', additionalAccess: access);
    await _load();
  }

  Future<void> _grantException(AdminUser user) async {
    final controller = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Onboarding exception'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          decoration: const InputDecoration(
              labelText: 'Business reason',
              hintText: 'Why is this exception required?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approve for 7 days')),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (approved != true || reason.isEmpty) return;
    final until = DateTime.now().add(const Duration(days: 7));
    if (_demo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Demo onboarding exception approved for 7 days.')));
      return;
    }
    await _service.updateAdminUser(
        userId: user.id,
        action: 'onboardingException',
        exceptionReason: reason,
        exceptionUntil: until);
    await _load();
  }

  Future<void> _selectAction(AdminUser user, String action) async {
    if (action == 'grantAccess') return _grantAccess(user);
    if (action == 'onboardingException') return _grantException(user);
    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove account permanently?'),
          content: Text(
            '${user.name.isEmpty ? user.email : user.name} will lose access and their profile will be removed. The audit event is retained.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove account'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    return _run(user, action);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = context.watch<AppProvider>().isAdmin || _demo;
    if (!allowed) {
      return const Scaffold(
          body: EmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Administrator access required',
        subtitle: 'This workspace is restricted to approved administrators.',
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: _loading
          ? const LoadingSpinner()
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load administration',
                  subtitle: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _AdminSummary(users: _users),
                    const SizedBox(height: 16),
                    _ModerationQueue(
                      reports: _reports,
                      onDecision: _reviewReport,
                    ),
                    const SizedBox(height: 16),
                    Text('People and access',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ..._users.map((user) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                                child: Text(user.name.isEmpty
                                    ? '?'
                                    : user.name[0].toUpperCase())),
                            title: Text(
                                user.name.isEmpty ? user.email : user.name),
                            subtitle: Text(
                                '${user.role} · ${user.disabled ? 'Disabled' : 'Active'}${user.additionalAccess.isEmpty ? '' : ' · ${user.additionalAccess.join(', ')}'}'),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Manage ${user.name}',
                              onSelected: (action) =>
                                  _selectAction(user, action),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: user.disabled
                                        ? 'activate'
                                        : 'deactivate',
                                    child: Text(user.disabled
                                        ? 'Activate account'
                                        : 'Deactivate account')),
                                const PopupMenuItem(
                                    value: 'grantAccess',
                                    child: Text('Grant additional access')),
                                const PopupMenuItem(
                                    value: 'onboardingException',
                                    child: Text('Onboarding exception')),
                                const PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove account')),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 16),
                    _FeatureGateCard(
                      readiness: _investorReadiness,
                      onChanged: (check, value) => setState(() {
                        _investorReadiness =
                            _investorReadiness.setCheck(check, value);
                      }),
                    ),
                    const SizedBox(height: 16),
                    const _AdminCapabilities(),
                  ],
                ),
    );
  }
}

class _ModerationQueue extends StatelessWidget {
  const _ModerationQueue({
    required this.reports,
    required this.onDecision,
  });

  final List<SafetyReport> reports;
  final void Function(SafetyReport report, String decision) onDecision;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Text('Safety moderation',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Chip(label: Text('${reports.length} open')),
            ]),
            const SizedBox(height: 6),
            if (reports.isEmpty)
              const Text('No open safety reports.')
            else
              ...reports.map((report) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.gpp_maybe_outlined),
                    ),
                    title: Text(report.category.toUpperCase()),
                    subtitle: Text(
                      '${report.details}\nTarget: ${report.targetId}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Review report',
                      onSelected: (decision) => onDecision(report, decision),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'resolved',
                          child: Text('Resolve'),
                        ),
                        PopupMenuItem(
                          value: 'escalated',
                          child: Text('Escalate'),
                        ),
                        PopupMenuItem(
                          value: 'dismissed',
                          child: Text('Dismiss'),
                        ),
                      ],
                    ),
                  )),
          ]),
        ),
      );
}

class _FeatureGateCard extends StatelessWidget {
  const _FeatureGateCard({required this.readiness, required this.onChanged});
  final FeatureReadiness readiness;
  final void Function(FeatureCheck check, bool value) onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(readiness.featureName,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              Chip(
                label: Text(readiness.isAvailable ? 'APPROVED' : 'NOT READY'),
                backgroundColor: readiness.isAvailable
                    ? AppColors.emeraldLight
                    : AppColors.amberLight,
              ),
            ]),
            const Text(
                'Proposed value: help users discover investor connections, understand funding fit, and request relevant introductions without turning RefSure into an unqualified fundraising directory.'),
            const SizedBox(height: 8),
            ...FeatureCheck.values.map((check) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: readiness.passed.contains(check),
                  title: Text(check.label),
                  onChanged: (value) => onChanged(check, value ?? false),
                )),
            Text(
              readiness.isAvailable
                  ? 'All checks passed. This feature is eligible for implementation.'
                  : 'The feature remains unavailable until every check passes.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    readiness.isAvailable ? AppColors.emerald : AppColors.amber,
              ),
            ),
          ]),
        ),
      );
}

class _AdminSummary extends StatelessWidget {
  const _AdminSummary({required this.users});
  final List<AdminUser> users;
  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metric('${users.length}', 'Accounts'),
            _metric('${users.where((u) => !u.disabled).length}', 'Active'),
            _metric(
                '${users.where((u) => u.additionalAccess.isNotEmpty).length}',
                'Custom access'),
          ]),
        ),
      );
  Widget _metric(String value, String label) => Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label)
      ]);
}

class _AdminCapabilities extends StatelessWidget {
  const _AdminCapabilities();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administrative controls',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('• Activate, deactivate, or remove accounts'),
            Text('• Grant scoped additional access'),
            Text('• Approve time-bound onboarding exceptions with a reason'),
            Text('• Review immutable administrator audit events'),
            Text('• Release features only after all five approval checks pass'),
          ]),
        ),
      );
}
