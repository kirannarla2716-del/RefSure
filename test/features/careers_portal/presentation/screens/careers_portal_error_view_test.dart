import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/features/careers_portal/presentation/screens/careers_portal_screen.dart';
import 'package:refsure/services/careers_portal_service.dart';

void main() {
  testWidgets('unsupported state does not overflow on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(280, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CareersPortalErrorView(
            message: 'No supported source returned open roles.',
            companyName: 'Example Company With A Long Name',
            onRetry: () {},
            officialCareersUrl: Uri.parse(
              'https://www.google.com/search?q=Example+Company+official+careers',
            ),
            diagnostics: const [
              CareersSourceDiagnostic(
                source: 'Greenhouse',
                slug: 'example-company-with-a-long-name',
                detail: 'The source returned HTTP 404.',
              ),
              CareersSourceDiagnostic(
                source: 'Workday',
                slug: 'examplecompanywithalongname',
                detail: 'The request timed out.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Copy careers link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
