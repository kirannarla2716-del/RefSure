// lib/providers/app_provider.dart — v2.0 FIXED
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/match_engine.dart';
import '../services/otp_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService      _auth    = AuthService();
  final FirestoreService _db      = FirestoreService();
  final StorageService   _storage = StorageService();
  final OtpService       _otp     = OtpService();

  AppUser?   _currentUser;
  bool       _authReady  = false;
  bool       _loading    = false;
  String?    _error;
  UserRole   _activeRole = UserRole.seeker;

  List<AppUser>         _providers    = [];
  List<AppUser>         _seekers      = [];
  List<Job>             _jobs         = [];
  List<Application>     _myApps       = [];
  List<Application>     _providerApps = [];
  List<AppNotification> _notifs       = [];
  JobFilter             _jobFilter    = const JobFilter();

  final List<StreamSubscription> _subs = [];

  AppUser?  get currentUser  => _currentUser;
  bool      get authReady    => _authReady;
  bool      get loading      => _loading;
  String?   get error        => _error;
  bool      get isLoggedIn   => _currentUser != null;
  bool      get isSeeker     => _activeRole == UserRole.seeker;
  bool      get isProvider   => _activeRole == UserRole.provider;
  UserRole  get activeRole   => _activeRole;
  JobFilter get jobFilter    => _jobFilter;

  List<AppUser>         get providers           => _providers;
  List<AppUser>         get seekers             => _seekers;
  List<Job>             get allJobs             => _jobs;
  List<Application>     get myApplications      => _myApps;
  List<Application>     get providerApplications => _providerApps;
  List<AppNotification> get notifications       => _notifs;
  int                   get unreadCount         => _notifs.where((n) => !n.read).length;

  List<Job> get activeJobs => _jobs.where((j) => j.status == 'active').toList();

  List<Job> get filteredJobs {
    var jobs = activeJobs;
    final f = _jobFilter;

    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      jobs = jobs.where((j) =>
        j.title.toLowerCase().contains(q) ||
        j.company.toLowerCase().contains(q) ||
        j.skills.any((s) => s.toLowerCase().contains(q)) ||
        j.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    if (f.workMode != null) {
      jobs = jobs.where((j) => j.workMode == f.workMode).toList();
    }
    if (f.location != null) {
      jobs = jobs.where((j) =>
        j.location.toLowerCase().contains(f.location!.toLowerCase()) ||
        j.workMode == 'Remote').toList();
    }
    if (f.hotOnly)    jobs = jobs.where((j) => j.isHot).toList();
    if (f.todayOnly) {
      final today = DateTime.now();
      jobs = jobs.where((j) =>
        j.postedAt.year == today.year &&
        j.postedAt.month == today.month &&
        j.postedAt.day == today.day).toList();
    }
    if (f.last10Days) {
      final cutoff = DateTime.now().subtract(const Duration(days: 10));
      jobs = jobs.where((j) => j.postedAt.isAfter(cutoff)).toList();
    }
    if (f.minExp != null) jobs = jobs.where((j) => j.maxExp >= f.minExp!).toList();
    if (f.maxExp != null) jobs = jobs.where((j) => j.minExp <= f.maxExp!).toList();
    if (f.tags.isNotEmpty) {
      jobs = jobs.where((j) => f.tags.any((t) => j.tags.contains(t))).toList();
    }

    switch (f.sortBy) {
      case JobSortBy.matchScore:
        if (_currentUser != null) {
          final user = _currentUser!;
          jobs.sort((a, b) =>
            MatchEngine.compute(seeker: user, job: b).score
            .compareTo(MatchEngine.compute(seeker: user, job: a).score));
        }
      case JobSortBy.recent:
        jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      case JobSortBy.hotFirst:
        jobs.sort((a, b) {
          if (a.isHot && !b.isHot) return -1;
          if (!a.isHot && b.isHot) return 1;
          return b.postedAt.compareTo(a.postedAt);
        });
    }
    return jobs;
  }

  AppProvider() { _initGuest(); }

  void _initGuest() {
    // GUEST MODE - bypasses Firebase auth for testing
    _currentUser = AppUser(
      id: 'guest_seeker_001',
      role: UserRole.seeker,
      name: 'Kiran (Guest)',
      headline: 'Software Engineer · 3 yrs exp',
      company: 'TCS',
      title: 'Software Engineer',
      location: 'Bangalore',
      experience: 3,
      skills: ['React', 'Node.js', 'TypeScript', 'AWS', 'Python'],
      bio: 'Full stack engineer looking for exciting opportunities at product companies.',
      email: 'kiran@guest.dev',
      profileComplete: 75,
      activelyLooking: true,
      noticePeriod: '30 days',
      expectedSalary: '20-30',
    );
    _activeRole = UserRole.seeker;
    _authReady = true;
    // Load jobs from Firestore (read-only is fine)
    _subs.add(_db.watchActiveJobs().listen((list) { _jobs = list; notifyListeners(); }));
    _subs.add(_db.watchProviders().listen((list) { _providers = list; notifyListeners(); }));
    notifyListeners();
    // Seed sample jobs if none exist
    _db.seedSampleJobs();
  }

  void _init() {
    _subs.add(_auth.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _authReady = true;
        _providers = [];
        _seekers = [];
        _jobs = [];
        _myApps = [];
        _providerApps = [];
        _notifs = [];
        notifyListeners();
        return;
      }
      await _loadUserData(firebaseUser.uid);
    }));
  }

  Future<void> _loadUserData(String uid) async {
    _authReady = true;
    _loading = true;
    notifyListeners();
    try {
      _subs.add(_db.watchUser(uid).listen((appUser) {
        if (appUser != null) {
          _currentUser = appUser;
          _activeRole  = appUser.role;
          notifyListeners();
        }
      }));
      _subs.add(_db.watchProviders().listen((list) {
        _providers = list;
        notifyListeners();
      }));
      _subs.add(_db.watchActiveJobs().listen((list) {
        _jobs = list;
        notifyListeners();
      }));
      _subs.add(_db.watchNotifications(uid).listen((list) {
        _notifs = list;
        notifyListeners();
      }));

      final user = await _db.getUser(uid);
      if (user != null) {
        _activeRole = user.role;
        if (user.role == UserRole.seeker) {
          _subs.add(_db.watchSeekerApplications(uid).listen((list) {
            _myApps = list;
            notifyListeners();
          }));
        } else {
          _subs.add(_db.watchProviderApplications(uid).listen((list) {
            _providerApps = list;
            notifyListeners();
          }));
          _subs.add(_db.watchSeekers().listen((list) {
            _seekers = list;
            notifyListeners();
          }));
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email, required String password,
    required String name, required UserRole role,
  }) async {
    _loading = true; notifyListeners();
    final r = await _auth.signUpWithEmail(email: email, password: password, name: name, role: role);
    _loading = false; notifyListeners();
    return r;
  }

  Future<AuthResult> signIn({
    required String email, required String password,
  }) async {
    _loading = true; notifyListeners();
    final r = await _auth.signInWithEmail(email: email, password: password);
    _loading = false; notifyListeners();
    return r;
  }

  Future<AuthResult> signInWithGoogle({UserRole role = UserRole.seeker}) async {
    _loading = true; notifyListeners();
    final r = await _auth.signInWithGoogle(role: role);
    _loading = false; notifyListeners();
    return r;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    await _db.updateUser(_currentUser!.id, data);
  }

  Future<String?> uploadResume() async {
    if (_currentUser == null) return null;
    final url = await _storage.uploadResumeFile(_currentUser!.id);
    if (url != null) await updateProfile({'resumeUrl': url});
    return url;
  }

  // ── OTP ─────────────────────────────────────────────────────

  Future<OtpSendResult> sendOrgEmailOtp(String email) async {
    if (_currentUser == null) {
      return OtpSendResult(success: false, error: 'Not logged in');
    }
    return _otp.sendOtp(userId: _currentUser!.id, email: email);
  }

  Future<OtpVerifyResult> verifyOrgEmailOtp(String email, String code) async {
    if (_currentUser == null) {
      return OtpVerifyResult(success: false, error: 'Not logged in');
    }
    final result = await _otp.verifyOtp(
      userId: _currentUser!.id, email: email, enteredOtp: code);
    if (result.success && result.companyName != null) {
      await _db.markOrgVerified(_currentUser!.id, email, result.companyName!);
    }
    return result;
  }

  bool isOrgEmail(String email) => _otp.isOrgEmail(email);

  // ── Filters ──────────────────────────────────────────────────

  void updateJobFilter(JobFilter filter) {
    _jobFilter = filter;
    notifyListeners();
  }

  void clearJobFilter() {
    _jobFilter = const JobFilter();
    notifyListeners();
  }

  // ── Jobs ─────────────────────────────────────────────────────

  Future<String?> postJob(Map<String, dynamic> data) async {
    if (_currentUser == null) return null;
    final job = Job(
      id: '',
      providerId: _currentUser!.id,
      company: _currentUser!.company ?? data['company'] ?? 'My Company',
      companyLogo: (_currentUser!.company ?? data['company'] ?? 'C')[0].toUpperCase(),
      title:       data['title'] ?? '',
      department:  data['department'] ?? 'Engineering',
      location:    data['location'] ?? '',
      workMode:    data['workMode'] ?? 'Hybrid',
      minExp:      data['minExp'] ?? 0,
      maxExp:      data['maxExp'] ?? 10,
      salaryMin:   data['salaryMin'] ?? 0,
      salaryMax:   data['salaryMax'] ?? 0,
      skills:      List<String>.from(data['skills'] ?? []),
      preferredSkills: List<String>.from(data['preferredSkills'] ?? []),
      tags:        List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? '',
      providerNote: data['providerNote'],
      deadline:    data['deadline'] ?? '2026-12-31',
      jobRefId:    '',
      isHot:       data['isHot'] ?? false,
      externalUrl: data['externalUrl'],
    );
    return await _db.postJob(job);
  }

  // ── Applications ─────────────────────────────────────────────

  Future<dynamic> applyToJob(Job job) async {
    if (_currentUser == null) return 'error';
    final already = await _db.hasApplied(job.id, _currentUser!.id);
    if (already) return 'already';

    final report = MatchEngine.compute(seeker: _currentUser!, job: job);
    if (report.score < 40) return 'low_match';

    final initStatus = report.score >= 80 ? AppStatus.strongMatch : AppStatus.pending;

    final app = Application(
      id: '', jobId: job.id, seekerId: _currentUser!.id,
      providerId: job.providerId, matchScore: report.score,
      matchReport: report, status: initStatus,
      strongMatchFlag: report.score >= 80,
    );
    await _db.submitApplication(app);

    await _db.createNotification(AppNotification(
      id: '', userId: job.providerId, type: 'application',
      text: '${_currentUser!.name} applied to ${job.title} — ${report.bandLabel}',
      actionRoute: '/jobs/${job.id}',
    ));
    return true;
  }

  Future<void> updateApplicationStatus(
    String appId, AppStatus status, {String? note}) async {
    await _db.updateApplicationStatus(appId, status, note: note);

    Application? app;
    try {
      app = _providerApps.firstWhere((a) => a.id == appId);
    } catch (_) { return; }

    final job = findJob(app.jobId);
    final statusTexts = {
      AppStatus.shortlisted: 'was shortlisted',
      AppStatus.referred:    'has been referred ✅',
      AppStatus.interview:   'has been scheduled for interview 📅',
      AppStatus.hired:       'has been hired! 🎉',
      AppStatus.notSelected: 'was not selected this time',
      AppStatus.closed:      'position has been closed',
    };
    if (statusTexts.containsKey(status)) {
      await _db.createNotification(AppNotification(
        id: '', userId: app.seekerId, type: 'status',
        text: 'Your application for ${job?.title ?? "a job"} ${statusTexts[status]}.',
        actionRoute: '/applications',
      ));
    }
  }

  // ── Match ─────────────────────────────────────────────────────

  MatchReport computeMatch(Job job) {
    if (_currentUser == null) {
      return MatchReport(
        score: 0, band: MatchBand.lowMatch, bandLabel: '🔴 Low Match',
        recommendation: 'Sign in to see your match.',
        matchedSkills: [], missingSkills: job.skills,
        strengths: [], gaps: [],
        skillScore: 0, experienceScore: 0, locationScore: 0, contextScore: 0);
    }
    return MatchEngine.compute(seeker: _currentUser!, job: job);
  }

  MatchReport computeMatchForSeeker(AppUser seeker, Job job) =>
      MatchEngine.compute(seeker: seeker, job: job);

  // ── Messaging ────────────────────────────────────────────────

  Stream<List<Message>> watchConversation(String otherId) {
    if (_currentUser == null) return Stream.value([]);
    return _db.watchConversation(_currentUser!.id, otherId);
  }

  Future<void> sendMessage(String toId, String text) async {
    if (_currentUser == null) return;
    await _db.sendMessage(
      Message(id: '', fromId: _currentUser!.id, toId: toId, text: text));
  }

  // ── Notifications ────────────────────────────────────────────

  Future<void> markAllNotifsRead() async {
    if (_currentUser == null) return;
    await _db.markAllNotifsRead(_currentUser!.id);
  }

  Future<void> markNotifRead(String id) => _db.markNotifRead(id);

  // ── Helpers ──────────────────────────────────────────────────

  AppUser? findUser(String id) {
    try { return [..._providers, ..._seekers].firstWhere((u) => u.id == id); }
    catch (_) { return null; }
  }

  Job? findJob(String id) {
    try { return _jobs.firstWhere((j) => j.id == id); }
    catch (_) { return null; }
  }
}

// ── JobFilter ─────────────────────────────────────────────────

enum JobSortBy { matchScore, recent, hotFirst }

class JobFilter {
  final String  query;
  final String? workMode;
  final String? location;
  final bool    hotOnly;
  final bool    todayOnly;
  final bool    last10Days;
  final int?    minExp;
  final int?    maxExp;
  final List<String> tags;
  final JobSortBy sortBy;

  const JobFilter({
    this.query = '',
    this.workMode,
    this.location,
    this.hotOnly    = false,
    this.todayOnly  = false,
    this.last10Days = false,
    this.minExp,
    this.maxExp,
    this.tags   = const [],
    this.sortBy = JobSortBy.matchScore,
  });

  JobFilter copyWith({
    String? query, String? workMode, String? location,
    bool? hotOnly, bool? todayOnly, bool? last10Days,
    int? minExp, int? maxExp, List<String>? tags, JobSortBy? sortBy,
  }) => JobFilter(
    query:      query      ?? this.query,
    workMode:   workMode   ?? this.workMode,
    location:   location   ?? this.location,
    hotOnly:    hotOnly    ?? this.hotOnly,
    todayOnly:  todayOnly  ?? this.todayOnly,
    last10Days: last10Days ?? this.last10Days,
    minExp:     minExp     ?? this.minExp,
    maxExp:     maxExp     ?? this.maxExp,
    tags:       tags       ?? this.tags,
    sortBy:     sortBy     ?? this.sortBy,
  );

  bool get isActive =>
      query.isNotEmpty || workMode != null || location != null ||
      hotOnly || todayOnly || last10Days ||
      minExp != null || maxExp != null || tags.isNotEmpty;

  int get activeCount {
    int n = 0;
    if (query.isNotEmpty) n++;
    if (workMode != null) n++;
    if (location != null) n++;
    if (hotOnly)  n++;
    if (todayOnly || last10Days) n++;
    if (minExp != null || maxExp != null) n++;
    n += tags.length;
    return n;
  }
}
