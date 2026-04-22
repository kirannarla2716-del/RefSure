// lib/screens/onboarding_screen.dart — v2.0
// Advanced onboarding: LinkedIn / CV upload / Manual + Org email OTP
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

const _skillOptions = [
  'React','Node.js','Python','Java','Go','TypeScript','AWS','GCP','Azure',
  'SQL','MongoDB','System Design','Product Strategy','Data Analysis',
  'Machine Learning','Kubernetes','Docker','Spring Boot','Kafka','Flutter',
  'iOS','Android','Leadership','Agile','UX Design','Finance','Marketing',
  'Django','FastAPI','Redis','GraphQL','Microservices','DevOps','Terraform',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;                          // 0=source, 1=profile, 2=skills, 3=details, 4=orgVerify
  OnboardingSource _source = OnboardingSource.manual;

  // Profile fields
  final _title    = TextEditingController();
  final _company  = TextEditingController();
  final _location = TextEditingController();
  final _bio      = TextEditingController();
  final _salary   = TextEditingController();
  final _linkedin = TextEditingController();
  double _exp = 2;
  String _notice = '30 days';
  final List<String> _skills = [];

  // Org OTP
  final _orgEmail = TextEditingController();
  final _otpCtrl  = TextEditingController();
  bool _otpSent   = false;
  bool _otpVerified = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  String? _otpError;

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose(); _company.dispose(); _location.dispose();
    _bio.dispose(); _salary.dispose(); _linkedin.dispose();
    _orgEmail.dispose(); _otpCtrl.dispose();
    super.dispose();
  }

  int get _totalSteps => _source == OnboardingSource.manual ? 5 : 4;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Column(children: [
      // Progress bar
      LinearProgressIndicator(
        value: (_step + 1) / _totalSteps,
        backgroundColor: AppColors.border,
        color: AppColors.primary, minHeight: 3),

      // Step indicator
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Text('Step ${_step + 1} of $_totalSteps', style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textHint)),
          const Spacer(),
          if (_otpVerified) Row(children: [
            const Icon(Icons.verified, size: 14, color: AppColors.emerald),
            const SizedBox(width: 4),
            Text('Org Verified', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emerald)),
          ]),
        ]),
      ),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: <Widget>[
          _sourceStep(),
          _profileStep(),
          _skillsStep(),
          _detailsStep(),
          _orgVerifyStep(),
        ][_step],
      )),
    ])),
  );

  // ── Step 0: Onboarding Source ───────────────────────────────
  Widget _sourceStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('How would you like to set up?', style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800)),
    Text('Choose the fastest way to build your profile.', style: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 24),

    _SourceCard(
      icon: '💼',
      title: 'Import from LinkedIn',
      subtitle: 'Paste your LinkedIn profile URL — we auto-fill your profile.',
      selected: _source == OnboardingSource.linkedin,
      onTap: () => setState(() => _source = OnboardingSource.linkedin),
    ),
    const SizedBox(height: 12),

    _SourceCard(
      icon: '📄',
      title: 'Upload Resume / CV',
      subtitle: 'Upload PDF or DOCX — we parse and fill your profile.',
      selected: _source == OnboardingSource.cvUpload,
      onTap: () => setState(() => _source = OnboardingSource.cvUpload),
    ),
    const SizedBox(height: 12),

    _SourceCard(
      icon: '✏️',
      title: 'Fill manually',
      subtitle: 'Complete the profile yourself, step by step.',
      selected: _source == OnboardingSource.manual,
      onTap: () => setState(() => _source = OnboardingSource.manual),
    ),

    const SizedBox(height: 28),

    // LinkedIn URL field (shown when LinkedIn selected)
    if (_source == OnboardingSource.linkedin) ...[
      TextField(controller: _linkedin,
        decoration: const InputDecoration(
          labelText: 'LinkedIn Profile URL',
          hintText: 'https://linkedin.com/in/yourname',
          prefixIcon: Icon(Icons.link))),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Text(
          '💡 LinkedIn import is in beta. We\'ll pre-fill your title and company. '
          'You\'ll verify and complete the rest.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary))),
      const SizedBox(height: 16),
    ],

    // CV upload option
    if (_source == OnboardingSource.cvUpload) ...[
      _CvUploadButton(),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Text(
          '💡 CV parsing extracts your skills, title, and experience. '
          'You\'ll review and complete the details.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary))),
      const SizedBox(height: 16),
    ],

    _nextBtn('Continue →', () => setState(() => _step = 1)),
  ]);

  // ── Step 1: Basic Profile ────────────────────────────────────
  Widget _profileStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('Your professional profile', style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800)),
    Text('Tell providers about your background.', style: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 20),

    _field('Current / Last Job Title *', _title, 'e.g. Software Engineer'),
    const SizedBox(height: 14),
    _field('Current / Last Company', _company, 'e.g. TCS, Infosys, Startup'),
    const SizedBox(height: 14),
    _field('Location', _location, 'e.g. Bangalore'),
    const SizedBox(height: 16),

    Text('Years of Experience', style: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Row(children: [
      Expanded(child: Slider(
        value: _exp, min: 0, max: 25, divisions: 25,
        activeColor: AppColors.primary,
        onChanged: (v) => setState(() => _exp = v))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Text('${_exp.round()} yrs', style: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: AppColors.primary))),
    ]),

    const SizedBox(height: 24),
    Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: () => setState(() => _step = 0),
        child: const Text('Back'))),
      const SizedBox(width: 12),
      Expanded(child: _nextBtn('Next →', () {
        if (_title.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please enter your job title')));
          return;
        }
        setState(() => _step = 2);
      })),
    ]),
  ]);

  // ── Step 2: Skills ───────────────────────────────────────────
  Widget _skillsStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('Your skills', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
    Text('Select all that apply — this drives your match score.',
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 16),

    Wrap(spacing: 8, runSpacing: 8, children: _skillOptions.map((s) {
      final on = _skills.contains(s);
      return FilterChip(
        label: Text(s),
        selected: on,
        onSelected: (_) => setState(() => on ? _skills.remove(s) : _skills.add(s)),
        selectedColor: AppColors.primary, checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(color: on ? AppColors.primary : AppColors.border),
        labelStyle: GoogleFonts.inter(
          color: on ? Colors.white : AppColors.textSecond,
          fontWeight: on ? FontWeight.w600 : FontWeight.w400));
    }).toList()),

    const SizedBox(height: 10),
    Text('${_skills.length} selected', style: GoogleFonts.inter(
      fontSize: 12, color: AppColors.textHint)),
    const SizedBox(height: 24),

    Row(children: [
      Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 1),
        child: const Text('Back'))),
      const SizedBox(width: 12),
      Expanded(child: _nextBtn('Next →', () {
        if (_skills.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Select at least 2 skills')));
          return;
        }
        setState(() => _step = 3);
      })),
    ]),
  ]);

  // ── Step 3: Additional Details ───────────────────────────────
  Widget _detailsStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('A bit more', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
    Text('Helps providers evaluate you better.', style: GoogleFonts.inter(
      fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 20),

    DropdownButtonFormField<String>(
      value: _notice,
      decoration: const InputDecoration(labelText: 'Notice Period'),
      items: ['Immediate','15 days','30 days','45 days','60 days','90 days']
          .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) => setState(() => _notice = v!)),
    const SizedBox(height: 14),
    _field('Expected CTC (LPA)', _salary, 'e.g. 20-30'),
    const SizedBox(height: 14),
    TextField(controller: _bio, maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Professional Summary (optional)',
        hintText: 'Brief overview of your background, goals, and what you\'re looking for...')),

    const SizedBox(height: 24),

    Row(children: [
      Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 2),
        child: const Text('Back'))),
      const SizedBox(width: 12),
      Expanded(child: _nextBtn('Next →', () => setState(() => _step = 4))),
    ]),
  ]);

  // ── Step 4: Org Email OTP Verification ───────────────────────
  Widget _orgVerifyStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('Verify your organisation', style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800)),
    Text('Get an "Org Verified" badge — 3× more referral requests.',
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 16),

    // Benefits
    _VerifyBenefit('🏆', 'Stand out to providers'),
    _VerifyBenefit('🔒', 'Trusted identity, more referrals'),
    _VerifyBenefit('⚡', 'Priority queue in provider dashboard'),

    const SizedBox(height: 20),

    if (!_otpVerified) ...[
      TextField(
        controller: _orgEmail,
        keyboardType: TextInputType.emailAddress,
        enabled: !_otpSent,
        decoration: InputDecoration(
          labelText: 'Work Email',
          hintText: 'yourname@company.com',
          prefixIcon: const Icon(Icons.business_outlined),
          suffixIcon: _otpSent
              ? const Icon(Icons.check, color: AppColors.emerald) : null)),

      if (_otpError != null) ...[
        const SizedBox(height: 8),
        Text(_otpError!, style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.red)),
      ],

      const SizedBox(height: 12),

      if (!_otpSent) ElevatedButton(
        onPressed: _sendingOtp ? null : _sendOtp,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: _sendingOtp
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Send Verification Code')),

      if (_otpSent) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
            letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: '6-digit OTP',
            hintText: '• • • • • •',
            counterText: '',
            helperText: 'Check your work email inbox',
            suffixIcon: TextButton(
              onPressed: _sendingOtp ? null : _sendOtp,
              child: const Text('Resend')))),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _verifyingOtp ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _verifyingOtp
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify Code')),
      ],
    ],

    if (_otpVerified) ...[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.emerald.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.verified, color: AppColors.emerald, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Organisation Verified! 🎉', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.emerald)),
            Text('Your profile now shows the Org Verified badge.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald.withOpacity(0.8))),
          ])),
        ])),
    ],

    const SizedBox(height: 24),

    Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: () => setState(() => _step = 3),
        child: const Text('Back'))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton(
        onPressed: _saving ? null : _finish,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_otpVerified ? 'Complete Setup 🚀' : 'Skip & Complete'))),
    ]),
  ]);

  // ── Helpers ────────────────────────────────────────────────

  Widget _field(String label, TextEditingController ctrl, String hint) =>
    TextField(controller: ctrl, decoration: InputDecoration(labelText: label, hintText: hint));

  Widget _nextBtn(String label, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    child: Text(label));

  Future<void> _sendOtp() async {
    if (_orgEmail.text.trim().isEmpty) {
      setState(() => _otpError = 'Please enter your work email');
      return;
    }
    final prov = context.read<AppProvider>();
    if (!prov.isOrgEmail(_orgEmail.text.trim())) {
      setState(() => _otpError = 'Please use a work email (not Gmail, Yahoo, etc.)');
      return;
    }
    setState(() { _sendingOtp = true; _otpError = null; });
    final result = await prov.sendOrgEmailOtp(_orgEmail.text.trim());
    setState(() { _sendingOtp = false; });
    if (result.success) {
      setState(() { _otpSent = true; });
    } else {
      setState(() => _otpError = result.error);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code');
      return;
    }
    setState(() { _verifyingOtp = true; _otpError = null; });
    final result = await context.read<AppProvider>()
        .verifyOrgEmailOtp(_orgEmail.text.trim(), _otpCtrl.text.trim());
    setState(() { _verifyingOtp = false; });
    if (result.success) {
      setState(() { _otpVerified = true; });
    } else {
      setState(() => _otpError = result.error);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);

    final prov = context.read<AppProvider>();

    // Build headline
    String headline = _title.text.trim();
    if (_exp.round() > 0) headline += ' · ${_exp.round()} yrs exp';

    await prov.updateProfile({
      'title':           _title.text.trim(),
      'company':         _company.text.trim(),
      'location':        _location.text.trim().isEmpty ? 'India' : _location.text.trim(),
      'experience':      _exp.round(),
      'skills':          _skills,
      'bio':             _bio.text.trim(),
      'noticePeriod':    _notice,
      'expectedSalary':  _salary.text.trim(),
      'activelyLooking': true,
      'profileComplete': _computeCompleteness(),
      'headline':        headline,
      'onboardingSource': _source.name,
      if (_linkedin.text.trim().isNotEmpty) 'linkedinUrl': _linkedin.text.trim(),
    });

    if (!mounted) return;
    context.go('/');
  }

  int _computeCompleteness() {
    int p = 30; // Base for being signed up
    if (_title.text.isNotEmpty)    p += 15;
    if (_company.text.isNotEmpty)  p += 10;
    if (_location.text.isNotEmpty) p += 5;
    if (_skills.length >= 3)       p += 15;
    if (_bio.text.isNotEmpty)      p += 10;
    if (_salary.text.isNotEmpty)   p += 5;
    if (_otpVerified)              p += 10;
    return p.clamp(0, 100);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final String icon, title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _SourceCard({required this.icon, required this.title,
    required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textPrimary)),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textSecond)),
        ])),
        if (selected)
          const Icon(Icons.check_circle, color: AppColors.primary),
      ]),
    ),
  );
}

class _CvUploadButton extends StatefulWidget {
  @override
  State<_CvUploadButton> createState() => _CvUploadButtonState();
}

class _CvUploadButtonState extends State<_CvUploadButton> {
  bool _uploading = false;
  String? _fileName;

  @override
  Widget build(BuildContext context) => Column(children: [
    OutlinedButton.icon(
      onPressed: _uploading ? null : _upload,
      icon: _uploading
          ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file),
      label: Text(_uploading ? 'Uploading...'
          : _fileName != null ? 'Uploaded: $_fileName'
          : 'Choose PDF or DOCX'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))),
    if (_fileName != null) ...[
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.check_circle, size: 14, color: AppColors.emerald),
        const SizedBox(width: 6),
        Text('CV uploaded successfully', style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.emerald)),
      ]),
    ],
  ]);

  Future<void> _upload() async {
    setState(() => _uploading = true);
    final url = await context.read<AppProvider>().uploadResume();
    setState(() {
      _uploading = false;
      if (url != null) _fileName = 'Resume uploaded';
    });
    if (!mounted) return;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload failed. Try again.')));
    }
  }
}

class _VerifyBenefit extends StatelessWidget {
  final String emoji, text;
  const _VerifyBenefit(this.emoji, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
    ]));
}
