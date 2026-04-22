// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Column(children: [
      const SizedBox(height: 32),
      // Logo
      Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text('R', style: GoogleFonts.inter(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Text('RefSure', style: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text('Where real referrals happen.', style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textHint)),
      ]),
      const SizedBox(height: 28),

      // Tab bar
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 4,
              offset: const Offset(0, 1))]),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
        ),
      ),
      const SizedBox(height: 8),

      Expanded(child: TabBarView(controller: _tab, children: const [
        _SignInForm(),
        _SignUpForm(),
      ])),
    ])),
  );
}

// ── Sign In ────────────────────────────────────────────────────
class _SignInForm extends StatefulWidget {
  const _SignInForm();
  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _email = TextEditingController();
  final _pw    = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_error != null) _ErrorBanner(_error!),
      TextField(controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
      const SizedBox(height: 12),
      TextField(controller: _pw, obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure)))),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _showReset,
          child: const Text('Forgot password?'))),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _loading ? null : _signIn,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Sign In')),
      const SizedBox(height: 16),
      _Divider(),
      const SizedBox(height: 16),
      _GoogleButton(onPressed: () async {
        setState(() { _loading = true; _error = null; });
        final r = await context.read<AppProvider>().signInWithGoogle();
        if (!mounted) return;
        setState(() => _loading = false);
        if (r.success) context.go('/');
        else setState(() => _error = r.error);
      }),
    ]),
  );

  Future<void> _signIn() async {
    if (_email.text.isEmpty || _pw.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final r = await context.read<AppProvider>().signIn(
      email: _email.text.trim(), password: _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) context.go('/');
    else setState(() => _error = r.error);
  }

  void _showReset() {
    final ctrl = TextEditingController(text: _email.text);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(controller: ctrl,
        decoration: const InputDecoration(labelText: 'Email')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await context.read<AppProvider>().signInWithGoogle();
          },
          child: const Text('Send Link')),
      ],
    ));
  }
}

// ── Sign Up ────────────────────────────────────────────────────
class _SignUpForm extends StatefulWidget {
  const _SignUpForm();
  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pw    = TextEditingController();
  UserRole _role = UserRole.seeker;
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_error != null) _ErrorBanner(_error!),

      // Role selector
      Row(children: [
        _RoleChip('🔍 Job Seeker', UserRole.seeker, _role,
          () => setState(() => _role = UserRole.seeker)),
        const SizedBox(width: 10),
        _RoleChip('🤝 Provider', UserRole.provider, _role,
          () => setState(() => _role = UserRole.provider)),
      ]),
      const SizedBox(height: 16),

      TextField(controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 12),
      TextField(controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
      const SizedBox(height: 12),
      TextField(controller: _pw, obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password (6+ chars)',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure)))),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _loading ? null : _signUp,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Create Account')),
      const SizedBox(height: 16),
      _Divider(),
      const SizedBox(height: 16),
      _GoogleButton(onPressed: () async {
        setState(() { _loading = true; _error = null; });
        final r = await context.read<AppProvider>().signInWithGoogle(role: _role);
        if (!mounted) return;
        setState(() => _loading = false);
        if (r.success) context.go('/onboarding');
        else setState(() => _error = r.error);
      }),
    ]),
  );

  Future<void> _signUp() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _pw.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.'); return;
    }
    if (_pw.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final r = await context.read<AppProvider>().signUp(
      email: _email.text.trim(), password: _pw.text,
      name: _name.text.trim(), role: _role);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) context.go('/onboarding');
    else setState(() => _error = r.error);
  }
}

// ── Shared sub-widgets ────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.redLight, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.red.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.red, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.inter(
        fontSize: 13, color: AppColors.red))),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider()),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('or', style: GoogleFonts.inter(
        fontSize: 12, color: AppColors.textHint))),
    const Expanded(child: Divider()),
  ]);
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: AppColors.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('G', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF4285F4))),
      const SizedBox(width: 10),
      Text('Continue with Google', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    ]),
  );
}

class _RoleChip extends StatelessWidget {
  final String label;
  final UserRole value, group;
  final VoidCallback onTap;
  const _RoleChip(this.label, this.value, this.group, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1)),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecond)),
      ),
    ));
  }
}


// ── Dev Quick Login (remove before production) ─────────────────
class _DevLoginButton extends StatefulWidget {
  const _DevLoginButton();
  @override
  State<_DevLoginButton> createState() => _DevLoginButtonState();
}

class _DevLoginButtonState extends State<_DevLoginButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Column(children: [
    OutlinedButton(
      onPressed: _loading ? null : () => _login('seeker@refsure.dev', 'Test@12345', 'Kiran (Seeker)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: const Color(0xFF0A66C2),
        side: const BorderSide(color: Color(0xFF0A66C2))),
      child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('⚡ Quick Login as Seeker')),
    const SizedBox(height: 8),
    OutlinedButton(
      onPressed: _loading ? null : () => _login('provider@refsure.dev', 'Test@12345', 'Ananya (Provider)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: const Color(0xFF057642),
        side: const BorderSide(color: Color(0xFF057642))),
      child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('⚡ Quick Login as Provider')),
  ]);

  Future<void> _login(String email, String password, String name) async {
    setState(() => _loading = true);
    final prov = context.read<AppProvider>();
    // Try sign in first
    var result = await prov.signIn(email: email, password: password);
    // If no account yet, create it
    if (!result.success) {
      final role = email.contains('provider') ? UserRole.provider : UserRole.seeker;
      result = await prov.signUp(email: email, password: password, name: name, role: role);
      if (result.success) {
        // Sign in after signup
        await prov.signIn(email: email, password: password);
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}
