import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/match_report.dart';

void main() {
  MatchReport report(DateTime computedAt) => MatchReport(
        score: 75,
        band: MatchBand.goodToGo,
        bandLabel: 'Good to Go',
        recommendation: 'Request a referral.',
        matchedSkills: const ['Dart'],
        missingSkills: const ['Firebase'],
        strengths: const ['Experience'],
        gaps: const [],
        skillScore: 50,
        experienceScore: 20,
        locationScore: 5,
        contextScore: 0,
        computedAt: computedAt,
      );

  test('toJson serializes computedAt without a Firestore Timestamp', () {
    final computedAt = DateTime.utc(2026, 7, 26, 12, 30);
    final encoded = jsonEncode(report(computedAt).toJson());
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;

    expect(decoded['computedAt'], computedAt.toIso8601String());
  });

  test('fromMap accepts Timestamp, ISO string, and callable timestamp maps', () {
    final computedAt = DateTime.utc(2026, 7, 26, 12, 30);
    final base = report(computedAt).toJson();

    expect(
      MatchReport.fromMap({
        ...base,
        'computedAt': Timestamp.fromDate(computedAt),
      }).computedAt,
      isA<DateTime>().having(
        (value) => value.isAtSameMomentAs(computedAt),
        'instant',
        isTrue,
      ),
    );
    expect(
      MatchReport.fromMap(base).computedAt,
      isA<DateTime>().having(
        (value) => value.isAtSameMomentAs(computedAt),
        'instant',
        isTrue,
      ),
    );
    expect(
      MatchReport.fromMap({
        ...base,
        'computedAt': {
          '_seconds': computedAt.millisecondsSinceEpoch ~/ 1000,
          '_nanoseconds': 0,
        },
      }).computedAt,
      isA<DateTime>().having(
        (value) => value.isAtSameMomentAs(computedAt),
        'instant',
        isTrue,
      ),
    );
  });
}
