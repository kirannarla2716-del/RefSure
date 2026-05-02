// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/enums/enums.dart';

class MatchReport {
  final int score;
  final MatchBand band;
  final String bandLabel;
  final String recommendation;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> strengths;
  final List<String> gaps;
  final int skillScore;
  final int experienceScore;
  final int locationScore;
  final int contextScore;
  final DateTime computedAt;

  MatchReport({
    required this.score,
    required this.band,
    required this.bandLabel,
    required this.recommendation,
    required this.matchedSkills,
    required this.missingSkills,
    required this.strengths,
    required this.gaps,
    required this.skillScore,
    required this.experienceScore,
    required this.locationScore,
    required this.contextScore,
    DateTime? computedAt,
  }) : computedAt = computedAt ?? DateTime.now();

  static MatchBand bandFromScore(int s) {
    if (s >= 90) return MatchBand.sureShotMatch;
    if (s >= 80) return MatchBand.excellentMatch;
    if (s >= 70) return MatchBand.goodToGo;
    if (s >= 60) return MatchBand.needsReview;
    return MatchBand.lowMatch;
  }

  static String labelFromBand(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch => '\u{1F3AF} Sure-shot Match',
    MatchBand.excellentMatch => '\u{2B50} Excellent Match',
    MatchBand.goodToGo      => '\u{2705} Good to Go',
    MatchBand.needsReview   => '\u{26A0}\u{FE0F} Needs Review',
    MatchBand.lowMatch      => '\u{1F534} Low Match',
  };

  Map<String, dynamic> toMap() => {
    'score': score,
    'band': band.name,
    'bandLabel': bandLabel,
    'recommendation': recommendation,
    'matchedSkills': matchedSkills,
    'missingSkills': missingSkills,
    'strengths': strengths,
    'gaps': gaps,
    'skillScore': skillScore,
    'experienceScore': experienceScore,
    'locationScore': locationScore,
    'contextScore': contextScore,
    'computedAt': Timestamp.fromDate(computedAt),
  };

  factory MatchReport.fromMap(Map<String, dynamic> d) {
    final score = d['score'] ?? 0;
    final band  = MatchBand.values.firstWhere(
      (b) => b.name == (d['band'] ?? 'lowMatch'),
      orElse: () => MatchBand.lowMatch);
    return MatchReport(
      score: score, band: band, bandLabel: d['bandLabel'] ?? '',
      recommendation: d['recommendation'] ?? '',
      matchedSkills: List<String>.from(d['matchedSkills'] ?? []),
      missingSkills: List<String>.from(d['missingSkills'] ?? []),
      strengths: List<String>.from(d['strengths'] ?? []),
      gaps: List<String>.from(d['gaps'] ?? []),
      skillScore: d['skillScore'] ?? 0,
      experienceScore: d['experienceScore'] ?? 0,
      locationScore: d['locationScore'] ?? 0,
      contextScore: d['contextScore'] ?? 0,
      computedAt: (d['computedAt'] as Timestamp?)?.toDate(),
    );
  }
}
