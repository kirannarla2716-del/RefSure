// lib/screens/dev_seed_screen.dart
//
// Development-only screen to seed and clear test data.
// Access: go to /#/dev-seed in the browser.
// REMOVE before production.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/seed/test_data_seeder.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});
  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  bool _seeding  = false;
  bool _clearing = false;
  String? _message;
  bool _success = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('🛠️ Dev: Seed Test Data')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── What gets seeded ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('What gets seeded:', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ..._items([
                '👤  2 Provider users  (Ananya @ Microsoft, Rohit @ Google)',
                '👤  4 Seeker users   (Karan-DevOps, Priya-QA, Arjun-FullStack, Sneha-BA)',
                '💼  6 Jobs           (DevOps, QA, SWE, BA-Payments, Data Eng, Frontend)',
                '📋  12 Applications  with intelligent match scores already computed',
                '📊  Various statuses (Applied / Shortlisted / Referred / Rejected)',
              ]),
            ])),

          const SizedBox(height: 16),

          // ── Match score preview ─────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Expected match scores:', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 10),
              ..._items([
                '✅  Karan (DevOps CV) → DevOps job: ~78–88%  Strongly Recommend',
                '✅  Priya (QA CV) → QA job: ~72–82%          Recommend',
                '✅  Sneha (BA CV) → BA Payments job: ~70–80% Recommend',
                '✅  Arjun (FullStack) → Frontend job: ~68–78% Recommend',
                '❌  Priya (QA) → DevOps job: ~25–35%          Not Recommended',
                '❌  Sneha (BA) → DevOps job: ~20–30%          Not Recommended',
              ], color: AppColors.primary),
            ])),

          const SizedBox(height: 16),

          // ── Result message ──────────────────────────────
          if (_message != null) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _success ? AppColors.emeraldLight : AppColors.redLight,
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(_success ? Icons.check_circle : Icons.error_outline,
                color: _success ? AppColors.emerald : AppColors.red),
              const SizedBox(width: 10),
              Expanded(child: Text(_message!, style: GoogleFonts.inter(
                fontSize: 13,
                color: _success ? AppColors.emerald : AppColors.red))),
            ])),

          const Spacer(),

          // ── Action buttons ──────────────────────────────
          ElevatedButton(
            onPressed: (_seeding || _clearing) ? null : _seed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppColors.primary),
            child: _seeding
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Seeding data into Firestore...'),
                  ])
                : const Text('🌱 Seed All Test Data')),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: (_seeding || _clearing) ? null : _clear,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red)),
            child: _clearing
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
                    SizedBox(width: 12),
                    Text('Clearing...'),
                  ])
                : const Text('🗑️ Clear All Seed Data')),

          const SizedBox(height: 12),

          Text(
            '⚠️  Remove this screen before going to production.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
        ]),
    ),
  );

  List<Widget> _items(List<String> items, {Color color = AppColors.textSecond}) =>
      items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(item, style: GoogleFonts.inter(fontSize: 12, color: color)))).toList();

  Future<void> _seed() async {
    setState(() { _seeding = true; _message = null; });
    final result = await TestDataSeeder.seed();
    setState(() {
      _seeding = false;
      _success = result.success;
      _message = result.message;
    });
  }

  Future<void> _clear() async {
    setState(() { _clearing = true; _message = null; });
    final result = await TestDataSeeder.clear();
    setState(() {
      _clearing = false;
      _success = result.success;
      _message = result.message;
    });
  }
}
