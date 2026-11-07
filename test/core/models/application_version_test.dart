// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/application.dart';

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  Application application({int version = 3}) => Application(
        id: 'app-1',
        jobId: 'job-1',
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        status: AppStatus.underReview,
        matchScore: 75,
        version: version,
      );

  test('persists application version to Firestore', () {
    expect(application().toFirestore()['version'], 3);
  });

  test('hydrates version and defaults legacy documents to version one', () {
    final snapshot = _MockDocumentSnapshot();
    when(() => snapshot.id).thenReturn('app-1');
    when(snapshot.data).thenReturn({
      'jobId': 'job-1',
      'seekerId': 'seeker-1',
      'providerId': 'provider-1',
      'status': 'pending',
      'matchScore': 70,
      'version': 4,
    });

    expect(Application.fromFirestore(snapshot).version, 4);

    when(snapshot.data).thenReturn({
      'jobId': 'job-1',
      'seekerId': 'seeker-1',
      'providerId': 'provider-1',
      'status': 'pending',
      'matchScore': 70,
    });
    expect(Application.fromFirestore(snapshot).version, 1);
  });

  test('copyWith preserves or explicitly advances version', () {
    final original = application();

    expect(original.copyWith(status: AppStatus.shortlisted).version, 3);
    expect(original.copyWith(version: 4).version, 4);
  });

  test('persists referral response and receipt metadata', () {
    final responseDueAt = DateTime.utc(2026, 8, 13);
    final respondedAt = DateTime.utc(2026, 8, 12);
    final data = application()
        .copyWith(
          status: AppStatus.referred,
          referralReceiptId: 'app-1',
          responseDueAt: responseDueAt,
          respondedAt: respondedAt,
          declineReason: 'Not enough relevant experience',
        )
        .toFirestore();

    expect(data['referralReceiptId'], 'app-1');
    expect(
      (data['responseDueAt'] as Timestamp).millisecondsSinceEpoch,
      responseDueAt.millisecondsSinceEpoch,
    );
    expect(
      (data['respondedAt'] as Timestamp).millisecondsSinceEpoch,
      respondedAt.millisecondsSinceEpoch,
    );
    expect(data['declineReason'], 'Not enough relevant experience');
  });
}
