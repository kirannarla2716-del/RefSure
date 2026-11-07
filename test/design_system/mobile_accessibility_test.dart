import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/design_system/atoms/loading_spinner.dart';
import 'package:refsure/design_system/molecules/match_score_ring.dart';
import 'package:refsure/design_system/molecules/profile_completeness_bar.dart';
import 'package:refsure/design_system/molecules/section_header.dart';
import 'package:refsure/design_system/molecules/trust_score_bar.dart';
import 'package:refsure/design_system/organisms/empty_state.dart';

Widget _app(
  Widget child, {
  Size size = const Size(320, 568),
  double textScale = 1,
  double keyboardInset = 0,
}) =>
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('loading indicator announces its purpose', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(
      const LoadingSpinner(semanticLabel: 'Loading available jobs'),
    ));

    expect(find.bySemanticsLabel('Loading available jobs'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Loading available jobs')),
      containsSemantics(
        label: 'Loading available jobs',
        isLiveRegion: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('score components clamp invalid backend values', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      MatchScoreRing(140),
      ProfileCompletenessBar(-20),
      TrustScoreBar(120),
    ])));

    expect(tester.takeException(), isNull);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('100  High Trust'), findsOneWidget);
  });

  testWidgets('empty state remains usable in keyboard-reduced viewport',
      (tester) async {
    await tester.pumpWidget(_app(
      const EmptyState(
        title: 'No referral requests yet',
        subtitle:
            'Complete your profile and request a referral to get started.',
        action: FilledButton(onPressed: null, child: Text('Browse jobs')),
      ),
      size: const Size(320, 360),
      textScale: 2,
      keyboardInset: 180,
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('Browse jobs'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('section header does not overflow on small screens',
      (tester) async {
    await tester.pumpWidget(_app(
      const Padding(
        padding: EdgeInsets.all(16),
        child: SectionHeader(
          title: 'Your latest referral applications and activity',
          action: TextButton(onPressed: null, child: Text('See all')),
        ),
      ),
      textScale: 2,
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('See all'), findsOneWidget);
  });
}
