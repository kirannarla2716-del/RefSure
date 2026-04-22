// lib/widgets/common.dart — v2.0
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/models.dart';
import '../utils/theme.dart';

// ── UserAvatar ─────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final bool showOnlineDot;
  const UserAvatar({super.key, required this.name, this.photoUrl,
    this.size = 40, this.showOnlineDot = false});

  Color get _bg {
    const colors = [
      Color(0xFF0A66C2), Color(0xFF057642), Color(0xFF7C3AED),
      Color(0xFFB45309), Color(0xFFCC1016), Color(0xFF4F46E5),
    ];
    return name.isEmpty ? colors[0] : colors[name.codeUnitAt(0) % colors.length];
  }

  String get _initials => name.trim().split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: photoUrl!, width: size, height: size, fit: BoxFit.cover,
          placeholder: (_, __) => _fallback,
          errorWidget: (_, __, ___) => _fallback));
    } else {
      avatar = _fallback;
    }
    if (!showOnlineDot) return avatar;
    return Stack(children: [
      avatar,
      Positioned(right: 2, bottom: 2, child: Container(
        width: size * 0.22, height: size * 0.22,
        decoration: BoxDecoration(
          color: AppColors.emerald, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5)))),
    ]);
  }

  Widget get _fallback => CircleAvatar(
    radius: size / 2, backgroundColor: _bg,
    child: Text(_initials, style: GoogleFonts.inter(
      color: Colors.white, fontWeight: FontWeight.w700,
      fontSize: size * 0.35)));
}

// ── VerifiedBadge ──────────────────────────────────────────────
class VerifiedBadge extends StatelessWidget {
  final bool isOrg;
  const VerifiedBadge({super.key, this.isOrg = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.verified, size: 14, color: isOrg ? AppColors.emerald : AppColors.blue),
    const SizedBox(width: 2),
    Text(isOrg ? 'Org Verified' : 'Verified', style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: isOrg ? AppColors.emerald : AppColors.blue)),
  ]);
}

// ── OrgVerifiedBadge ───────────────────────────────────────────
class OrgBadge extends StatelessWidget {
  final String? company;
  const OrgBadge({super.key, this.company});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.emerald.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.domain_verification, size: 12, color: AppColors.emerald),
      const SizedBox(width: 4),
      Text('${company ?? "Org"} Verified', style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emerald)),
    ]));
}

// ── SkillChip ──────────────────────────────────────────────────
class SkillChip extends StatelessWidget {
  final String skill;
  final bool highlight, matched;
  final bool compact;
  const SkillChip(this.skill, {super.key,
    this.highlight = false, this.matched = false, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
    decoration: BoxDecoration(
      color: matched ? AppColors.emeraldLight : highlight ? AppColors.primaryLight : AppColors.bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: matched ? AppColors.emerald.withOpacity(0.4)
            : highlight ? AppColors.primary.withOpacity(0.3)
            : AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (matched) ...[
        const Icon(Icons.check, size: 10, color: AppColors.emerald),
        const SizedBox(width: 3),
      ],
      Text(skill, style: GoogleFonts.inter(
        fontSize: compact ? 11 : 12, fontWeight: FontWeight.w500,
        color: matched ? AppColors.emerald
            : highlight ? AppColors.primary : AppColors.textSecond)),
    ]));
}

// ── StatusPill ─────────────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String status, label;
  const StatusPill({super.key, required this.status, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.statusBg(status), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.statusFg(status))));
}

// ── WorkModePill ───────────────────────────────────────────────
class WorkModePill extends StatelessWidget {
  final String mode;
  const WorkModePill(this.mode, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.workModeBg(mode), borderRadius: BorderRadius.circular(20)),
    child: Text(mode, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.workModeFg(mode))));
}

// ── MatchScoreRing ─────────────────────────────────────────────
class MatchScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;
  const MatchScoreRing(this.score, {super.key, this.size = 56, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.matchScoreColor(score);
    return CircularPercentIndicator(
      radius: size / 2, lineWidth: size * 0.1,
      percent: score / 100, backgroundColor: color.withOpacity(0.15),
      progressColor: color,
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$score', style: GoogleFonts.inter(
          fontSize: size * 0.28, fontWeight: FontWeight.w800, color: color)),
        if (showLabel) Text('%', style: GoogleFonts.inter(
          fontSize: size * 0.15, color: color)),
      ]),
      animation: true, animationDuration: 800,
    );
  }
}

// ── MatchBandPill ──────────────────────────────────────────────
class MatchBandPill extends StatelessWidget {
  final MatchBand band;
  final String label;
  final bool large;
  const MatchBandPill({super.key, required this.band, required this.label, this.large = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
    decoration: BoxDecoration(
      color: AppColors.matchBg(band), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.matchFg(band).withOpacity(0.3))),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: large ? 13 : 11, fontWeight: FontWeight.w700,
      color: AppColors.matchFg(band))));
}

// ── TagChip ────────────────────────────────────────────────────
class TagChip extends StatelessWidget {
  final String tag;
  const TagChip(this.tag, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.accentLight, borderRadius: BorderRadius.circular(4)),
    child: Text('#$tag', style: GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent)));
}

// ── HotBadge ───────────────────────────────────────────────────
class HotBadge extends StatelessWidget {
  const HotBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(4)),
    child: const Text('🔥 HOT', style: TextStyle(
      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)));
}

// ── SectionCard ────────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const SectionCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8), onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
        child: child)));
}

// ── SectionHeader ──────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const Spacer(),
    if (action != null) action!,
  ]);
}

// ── InfoRow ────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoRow(this.icon, this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: color ?? AppColors.textHint),
    const SizedBox(width: 4),
    Text(text, style: GoogleFonts.inter(fontSize: 12, color: color ?? AppColors.textSecond)),
  ]);
}

// ── StatBox ────────────────────────────────────────────────────
class StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const StatBox({super.key, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: valueColor ?? AppColors.textPrimary)),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
  ]);
}

// ── EmptyState ─────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.emoji, required this.title,
    required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
          textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ])));
}

// ── LoadingSpinner ─────────────────────────────────────────────
class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

// ── TrustScoreBar ──────────────────────────────────────────────
class TrustScoreBar extends StatelessWidget {
  final double score;
  const TrustScoreBar(this.score, {super.key});

  Color get _color => score >= 70 ? AppColors.emerald
      : score >= 40 ? AppColors.amber : AppColors.red;

  String get _label => score >= 70 ? 'High Trust'
      : score >= 40 ? 'Building Trust' : 'New';

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('Trust Score', style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecond)),
      const Spacer(),
      Text('${score.round()}  $_label', style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
    ]),
    const SizedBox(height: 6),
    ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100, minHeight: 6, backgroundColor: _color.withOpacity(0.15),
        color: _color)),
  ]);
}

// ── ProfileCompletenessBar ─────────────────────────────────────
class ProfileCompletenessBar extends StatelessWidget {
  final int percent;
  const ProfileCompletenessBar(this.percent, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80 ? AppColors.emerald
        : percent >= 60 ? AppColors.primary : AppColors.amber;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Profile Strength', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecond)),
        const Spacer(),
        Text('$percent%', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100, minHeight: 6,
          backgroundColor: color.withOpacity(0.15), color: color)),
    ]);
  }
}
