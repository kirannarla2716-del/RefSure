// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:refsure/core/enums/enums.dart';

/// Single source of truth for colour tokens.
///
/// Palette:
/// - Background: pure white surfaces with a faint neutral canvas.
/// - Brand: light sea green for primary actions, accents, and badges.
/// - Semantics: tuned to coexist with the sea-green brand on a light theme.
class AppColors {
  // ── Brand ────────────────────────────────────────────────────
  /// Light sea green — primary brand colour for buttons, links, accents.
  static const primary      = Color(0xFF20B2AA);
  /// Hover / pressed state for the primary colour.
  static const primaryDark  = Color(0xFF178F88);
  /// 8% tinted surface for selected chips, badges, and subtle highlights.
  static const primaryLight = Color(0xFFE6F7F6);
  /// Secondary accent — a deeper teal that pairs with the primary.
  static const accent       = Color(0xFF0E7C7B);
  static const accentLight  = Color(0xFFE0F2F1);

  // ── Surface ──────────────────────────────────────────────────
  /// App canvas. A near-white with the faintest cool tint so that white
  /// cards still read as elevated.
  static const bg           = Color(0xFFF7FAFA);
  static const surface      = Colors.white;
  static const surfaceHover = Color(0xFFF1F7F7);
  static const border       = Color(0xFFE2E8E8);
  static const divider      = Color(0xFFEBEFEF);

  // ── Text ─────────────────────────────────────────────────────
  static const textPrimary  = Color(0xFF1A2A2A);
  static const textSecond   = Color(0xFF5C6B6B);
  static const textHint     = Color(0xFF8A9999);

  // ── Semantic ─────────────────────────────────────────────────
  static const emerald      = Color(0xFF0F8A6A);
  static const emeraldLight = Color(0xFFE6F4EE);
  static const amber        = Color(0xFFB45309);
  static const amberLight   = Color(0xFFFEF3C7);
  /// Informational tone — kept distinct from primary so banners stand out.
  static const info         = Color(0xFF1F8CB7);
  static const infoLight    = Color(0xFFE3F2F8);
  static const red          = Color(0xFFC03A40);
  static const redLight     = Color(0xFFFCEEEE);
  static const purple       = Color(0xFF6D5BD0);
  static const purpleLight  = Color(0xFFEFEBFA);
  static const gold         = Color(0xFFAA7C12);
  static const goldLight    = Color(0xFFFBF3DD);

  // ── Match band colours ───────────────────────────────────────
  static Color matchBg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch  => emeraldLight,
    MatchBand.excellentMatch => primaryLight,
    MatchBand.goodToGo       => purpleLight,
    MatchBand.needsReview    => amberLight,
    MatchBand.lowMatch       => redLight,
  };

  static Color matchFg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch  => emerald,
    MatchBand.excellentMatch => primary,
    MatchBand.goodToGo       => purple,
    MatchBand.needsReview    => amber,
    MatchBand.lowMatch       => red,
  };

  // ── Status colours ───────────────────────────────────────────
  static Color statusBg(String s) => switch (s) {
    'pending'      => bg,
    'underReview'  => infoLight,
    'strongMatch'  => emeraldLight,
    'needsReview'  => amberLight,
    'shortlisted'  => primaryLight,
    'referred'     => emeraldLight,
    'interview'    => infoLight,
    'hired'        => emeraldLight,
    'notSelected'  => redLight,
    'closed'       => bg,
    _              => bg,
  };

  static Color statusFg(String s) => switch (s) {
    'pending'      => textHint,
    'underReview'  => info,
    'strongMatch'  => emerald,
    'needsReview'  => amber,
    'shortlisted'  => primary,
    'referred'     => emerald,
    'interview'    => info,
    'hired'        => emerald,
    'notSelected'  => red,
    'closed'       => textHint,
    _              => textHint,
  };

  // ── Work-mode colours ────────────────────────────────────────
  static Color workModeBg(String m) => switch (m) {
    'Remote'  => emeraldLight,
    'Hybrid'  => amberLight,
    'On-site' => primaryLight,
    _         => bg,
  };

  static Color workModeFg(String m) => switch (m) {
    'Remote'  => emerald,
    'Hybrid'  => amber,
    'On-site' => primary,
    _         => textSecond,
  };

  /// Maps a 0–100 match score to a foreground colour.
  static Color matchScoreColor(int score) {
    if (score >= 90) return emerald;
    if (score >= 80) return primary;
    if (score >= 70) return accent;
    if (score >= 60) return amber;
    return red;
  }
}
