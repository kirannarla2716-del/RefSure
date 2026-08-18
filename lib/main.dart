// lib/main.dart — v2.0
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:refsure/core/di/injection.dart';
import 'package:refsure/firebase_options.dart';
import 'package:refsure/l10n/generated/app_localizations.dart';
import 'package:refsure/providers/app_provider.dart';
import 'package:refsure/router.dart';
import 'package:refsure/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final runtime = RefSureRuntimeConfig.fromBuild..validate(isWeb: kIsWeb);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final shouldActivateAppCheck =
      runtime.enableAppCheck && !runtime.useFirebaseEmulators;
  if (shouldActivateAppCheck) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(runtime.appCheckWebKey),
      appleProvider: AppleProvider.appAttest,
    );
  }
  configureDependencies();
  runApp(const RefSureApp());
}

class RefSureApp extends StatelessWidget {
  const RefSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const _RouterWrapper(),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  const _RouterWrapper();
  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= buildRouter(context.read<AppProvider>());
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final router = _router;
    if (router == null) return const SizedBox.shrink();
    return MaterialApp.router(
      title: 'RefSure',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
