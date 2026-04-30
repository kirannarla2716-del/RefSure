// lib/router.dart — v2.0 FIXED
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_screen.dart' as auth_feature;
import 'providers/app_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screens.dart';
import 'screens/feature_screens.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter buildRouter(AppProvider prov) => GoRouter(
  refreshListenable: prov,
  redirect: (context, state) {
    // GUEST MODE - no auth redirect
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, __) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const auth_feature.AuthScreen(),
    )),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/verify-org',  builder: (_, __) => const OrgVerifyScreen()),
    GoRoute(path: '/post-job',    builder: (_, __) => const PostJobScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const _EditProfileScreen()),
    GoRoute(
      path: '/providers/:id',
      builder: (_, state) =>
          ProviderDetailScreen(providerId: state.pathParameters['id']!)),
    GoRoute(
      path: '/jobs/:id',
      builder: (_, state) =>
          JobDetailScreen(jobId: state.pathParameters['id']!)),
    GoRoute(
      path: '/messages/:id',
      builder: (_, state) =>
          ChatScreen(otherId: state.pathParameters['id']!)),

    // Shell with bottom nav
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (ctx, state, child) => _ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/',            builder: (_, __) => const _HomeRouter()),
        GoRoute(path: '/jobs',        builder: (_, __) => const JobsScreen()),
        GoRoute(path: '/providers',   builder: (_, __) => const ProvidersScreen()),
        GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
        GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/messages',    builder: (_, __) => const MessagesScreen()),
      ],
    ),
  ],
);

class _HomeRouter extends StatelessWidget {
  const _HomeRouter();
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return prov.isProvider
        ? const ProviderDashboardScreen()
        : const HomeScreen();
  }
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  static const _seekerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined),   activeIcon: Icon(Icons.home),       label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.work_outline),    activeIcon: Icon(Icons.work),       label: 'Jobs'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline),  activeIcon: Icon(Icons.people),     label: 'Providers'),
    BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Applied'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline),  activeIcon: Icon(Icons.person),     label: 'Profile'),
  ];

  static const _providerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.work_outline),       activeIcon: Icon(Icons.work),      label: 'Jobs'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline),     activeIcon: Icon(Icons.people),    label: 'Seekers'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),activeIcon: Icon(Icons.chat_bubble),label: 'Messages'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline),     activeIcon: Icon(Icons.person),    label: 'Profile'),
  ];

  static const _seekerRoutes   = ['/', '/jobs', '/providers', '/applications', '/profile'];
  static const _providerRoutes = ['/', '/jobs', '/providers', '/messages',     '/profile'];

  int _currentIndex(String location, bool isProvider) {
    final routes = isProvider ? _providerRoutes : _seekerRoutes;
    for (int i = 0; i < routes.length; i++) {
      if (location == routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final prov       = context.watch<AppProvider>();
    final isProvider = prov.isProvider;
    final location   = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final index      = _currentIndex(location, isProvider);
    final routes     = isProvider ? _providerRoutes : _seekerRoutes;
    final unread     = prov.unreadCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0)))),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.go(routes[i]),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedItemColor: const Color(0xFF0A66C2),
          unselectedItemColor: const Color(0xFF999999),
          items: isProvider ? _providerItems : _seekerItems,
        ),
      ),
    );
  }
}

// Simple edit profile screen
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _title, _company, _loc, _bio;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    _title   = TextEditingController(text: user?.title ?? '');
    _company = TextEditingController(text: user?.company ?? '');
    _loc     = TextEditingController(text: user?.location ?? '');
    _bio     = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _title.dispose(); _company.dispose(); _loc.dispose(); _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Profile'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: _title,
        decoration: const InputDecoration(labelText: 'Job Title')),
      const SizedBox(height: 14),
      TextField(controller: _company,
        decoration: const InputDecoration(labelText: 'Company')),
      const SizedBox(height: 14),
      TextField(controller: _loc,
        decoration: const InputDecoration(labelText: 'Location')),
      const SizedBox(height: 14),
      TextField(controller: _bio, maxLines: 4,
        decoration: const InputDecoration(labelText: 'Bio / Summary')),
    ]),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AppProvider>().updateProfile({
      'title':    _title.text.trim(),
      'company':  _company.text.trim(),
      'location': _loc.text.trim(),
      'bio':      _bio.text.trim(),
    });
    if (mounted) { setState(() => _saving = false); context.pop(); }
  }
}
