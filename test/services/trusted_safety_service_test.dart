import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/services/trusted_safety_service.dart';

class _FakeSafetyTransport implements TrustedSafetyTransport {
  String? functionName;
  Map<String, dynamic>? data;
  Map<String, dynamic> response = {
    'reportId': 'report-1',
    'idempotent': false,
  };

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    this.functionName = functionName;
    this.data = data;
    return response;
  }
}

void main() {
  test('safety report uses trusted callable with bounded fields', () async {
    final transport = _FakeSafetyTransport();
    final service = TrustedSafetyService(transport: transport);
    final reportId = await service.reportUser(
      targetId: 'provider-1',
      category: 'fraud',
      details: 'Requested payment for a referral.',
      contextId: 'conversation:provider-1',
    );
    expect(reportId, 'report-1');
    expect(transport.functionName, 'reportUser');
    expect(transport.data?['targetId'], 'provider-1');
    expect(transport.data?['category'], 'fraud');
    expect(transport.data?['details'], 'Requested payment for a referral.');
    expect(transport.data?['commandId'], startsWith('report:'));
  });

  test('admin moderation list parses trusted report records', () async {
    final transport = _FakeSafetyTransport();
    transport.response = {
      'reports': [
        {
          'id': 'report-1',
          'reporterId': 'seeker-1',
          'targetId': 'provider-1',
          'category': 'fraud',
          'details': 'Requested payment.',
          'status': 'open',
          'createdAt': '2026-08-11T10:00:00.000Z',
        }
      ],
    };
    final reports =
        await TrustedSafetyService(transport: transport).listReports();
    expect(transport.functionName, 'adminListSafetyReports');
    expect(reports.single.id, 'report-1');
    expect(reports.single.category, 'fraud');
  });

  test('admin moderation decision uses trusted callable', () async {
    final transport = _FakeSafetyTransport();
    await TrustedSafetyService(transport: transport).reviewReport(
      reportId: 'report-1',
      decision: 'resolved',
      note: 'Reviewed supporting context.',
    );
    expect(transport.functionName, 'adminReviewSafetyReport');
    expect(transport.data?['reportId'], 'report-1');
    expect(transport.data?['decision'], 'resolved');
    expect(transport.data?['commandId'], startsWith('moderation:'));
  });
}
