import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/features/careers_portal/data/careers_portal_repository.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_cubit.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';
import 'package:refsure/features/careers_portal/presentation/screens/careers_portal_screen.dart';
import 'package:refsure/providers/app_provider.dart';
import 'package:refsure/services/careers_portal_service.dart';

class _MockAppProvider extends Mock implements AppProvider {}

class _MockRepository extends Mock implements CareersPortalRepository {}

class _CompanyHost extends StatefulWidget {
  const _CompanyHost({
    required this.appProvider,
    required this.cubit,
  });

  final AppProvider appProvider;
  final CareersPortalCubit cubit;

  @override
  State<_CompanyHost> createState() => _CompanyHostState();
}

class _CompanyHostState extends State<_CompanyHost> {
  String company = 'Company A';

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<AppProvider>.value(
        value: widget.appProvider,
        child: BlocProvider<CareersPortalCubit>.value(
          value: widget.cubit,
          child: MaterialApp(
            home: Stack(
              children: [
                CareersPortalScreen(
                  key: const ValueKey('careers-screen'),
                  initialCompany: company,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: TextButton(
                    onPressed: () => setState(() => company = 'Company B'),
                    child: const Text('Switch company'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

void main() {
  testWidgets(
    'same-route company update resets and fetches the new company',
    (tester) async {
      final appProvider = _MockAppProvider();
      final repository = _MockRepository();
      when(() => appProvider.isProvider).thenReturn(true);
      when(
        () => repository.fetchJobs(
          any(),
          filterLast30Days: true,
        ),
      ).thenAnswer(
        (invocation) async => CareersPortalResult(
          jobs: const [],
          platform: AtsPlatform.greenhouse,
          companySlug:
              invocation.positionalArguments.first.toString().toLowerCase(),
          totalFetched: 0,
        ),
      );
      final cubit = CareersPortalCubit(repository: repository);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _CompanyHost(appProvider: appProvider, cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company A'), findsOneWidget);
      verify(
        () => repository.fetchJobs(
          'Company A',
          filterLast30Days: true,
        ),
      ).called(1);

      await tester.tap(find.text('Switch company'));
      await tester.pumpAndSettle();

      expect(find.text('Company B'), findsOneWidget);
      expect(
        cubit.state,
        isA<CareersPortalLoaded>().having(
          (state) => state.companyName,
          'company',
          'Company B',
        ),
      );
      verify(
        () => repository.fetchJobs(
          'Company B',
          filterLast30Days: true,
        ),
      ).called(1);
      expect(tester.takeException(), isNull);
    },
  );
}
