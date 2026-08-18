import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/services/trusted_account_service.dart';

class _FakeTransport implements TrustedAccountTransport {
  _FakeTransport({this.response, this.error});

  final Map<String, dynamic>? response;
  final Exception? error;
  String? functionName;
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    this.functionName = functionName;
    this.data = data;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  test('role change uses callable transport with command data', () async {
    final transport = _FakeTransport(
      response: {
        'role': 'provider',
        'idempotent': false,
      },
    );
    final service = TrustedAccountService(transport: transport);

    final result = await service.changeRole(
      UserRole.provider,
      commandId: 'role-command-1',
    );

    expect(transport.functionName, 'changeRole');
    expect(transport.data, {
      'role': 'provider',
      'commandId': 'role-command-1',
    });
    expect(result.role, UserRole.provider);
    expect(result.idempotent, isFalse);
  });

  test('invalid role response is rejected', () async {
    final service = TrustedAccountService(
      transport: _FakeTransport(response: {'role': 'administrator'}),
    );

    expect(
      () => service.changeRole(UserRole.provider),
      throwsA(
        isA<TrustedAccountException>()
            .having((error) => error.code, 'code', 'invalid-response'),
      ),
    );
  });

  test('transport errors preserve trusted account semantics', () async {
    final service = TrustedAccountService(
      transport: _FakeTransport(
        error: const TrustedAccountException('permission-denied', 'Denied'),
      ),
    );

    expect(
      () => service.changeRole(UserRole.seeker),
      throwsA(
        isA<TrustedAccountException>()
            .having((error) => error.code, 'code', 'permission-denied'),
      ),
    );
  });

  test('admin list maps trusted callable users', () async {
    final transport = _FakeTransport(response: {
      'users': [
        {
          'id': 'user-1',
          'name': 'Beta User',
          'email': 'beta@refsure.in',
          'role': 'seeker',
          'disabled': false,
          'additionalAccess': ['support'],
        },
      ],
    });
    final service = TrustedAccountService(transport: transport);

    final users = await service.listAdminUsers();

    expect(transport.functionName, 'adminListUsers');
    expect(users.single.id, 'user-1');
    expect(users.single.additionalAccess, ['support']);
  });

  test('admin update sends scoped and auditable command data', () async {
    final transport = _FakeTransport(response: {'idempotent': false});
    final service = TrustedAccountService(transport: transport);

    await service.updateAdminUser(
      userId: 'user-1',
      action: 'grantAccess',
      additionalAccess: const ['support'],
      commandId: 'admin-command-1',
    );

    expect(transport.functionName, 'adminManageUser');
    expect(transport.data, {
      'userId': 'user-1',
      'action': 'grantAccess',
      'additionalAccess': ['support'],
      'commandId': 'admin-command-1',
    });
  });

  test('privacy request uses the trusted account callable', () async {
    final transport = _FakeTransport(response: {
      'requestId': 'user-1_data_export',
      'status': 'pending',
      'idempotent': false,
    });
    final service = TrustedAccountService(transport: transport);

    final result = await service.requestPrivacyAction('data_export');

    expect(transport.functionName, 'requestPrivacy');
    expect(transport.data?['type'], 'data_export');
    expect(transport.data?['commandId'], startsWith('privacy-data_export-'));
    expect(result.requestId, 'user-1_data_export');
    expect(result.status, 'pending');
    expect(result.idempotent, isFalse);
  });
}
