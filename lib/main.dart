// lib/main.dart — v2.0
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    if (_router == null) return const SizedBox.shrink();
    return MaterialApp.router(
      title: 'RefSure',
      theme: buildTheme(),
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
