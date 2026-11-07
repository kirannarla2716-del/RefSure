import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/design_system/organisms/job_card.dart';
import 'package:refsure/providers/app_provider.dart';

class _MockAppProvider extends Mock implements AppProvider {}

void main() {
  for (final width in [320.0, 375.0]) {
    testWidgets('job card does not overflow at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = _MockAppProvider();
      final job = Job(
        id: 'job-narrow',
        providerId: 'provider-1',
        company: 'A Company With A Long Name',
        companyLogo: 'A',
        title: 'Senior Cross-Platform Application Engineer',
        department: 'Product Engineering',
        location: 'Bengaluru',
        workMode: 'Hybrid',
        minExp: 3,
        maxExp: 8,
        skills: const ['Dart', 'Flutter', 'Firebase', 'TypeScript', 'GraphQL'],
        description: 'Build products',
        deadline: '2026-12-31',
        applicants: 1234,
      );
      when(() => provider.currentUser).thenReturn(null);
      when(() => provider.isSeeker).thenReturn(true);
      when(() => provider.myApplications).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: JobCard(job: job)),
            ),
          ),
        ),
      );

      expect(find.text('Request referral'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed referral request releases loading and allows retry',
      (tester) async {
    final provider = _MockAppProvider();
    final job = Job(
      id: 'job-1',
      providerId: 'provider-1',
      company: 'Acme',
      companyLogo: 'A',
      title: 'Engineer',
      department: 'Engineering',
      location: 'Remote',
      workMode: 'Remote',
      minExp: 1,
      maxExp: 5,
      skills: const ['Dart'],
      description: 'Build products',
      deadline: '2026-12-31',
    );
    when(() => provider.currentUser).thenReturn(null);
    when(() => provider.isSeeker).thenReturn(true);
    when(() => provider.myApplications).thenReturn([]);
    when(() => provider.error).thenReturn('Referral service unavailable.');
    when(() => provider.applyToJob(job))
        .thenAnswer((_) async => throw Exception('offline'));

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: JobCard(job: job),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Request referral'));
    await tester.pumpAndSettle();

    expect(find.text('Request referral'), findsOneWidget);
    expect(find.text('Referral service unavailable.'), findsOneWidget);

    await tester.tap(find.text('Request referral'));
    await tester.pumpAndSettle();
    verify(() => provider.applyToJob(job)).called(2);
  });
}
