// lib/providers/app_provider.dart — v2.0 FIXED
// ignore_for_file: argument_type_not_assignable, require_trailing_commas
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/test_data_seeder.dart';
import '../core/models/external_job.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/match_engine.dart';
import '../services/otp_service.dart';
import '../services/trusted_application_service.dart';
import '../services/trusted_account_service.dart';
import '../services/trusted_gratitude_service.dart';
import '../services/trusted_safety_service.dart';

bool shouldUseDemoReferralFallback({
  required bool demoMode,
  required String jobId,
  required String errorCode,
}) =>
    demoMode &&
    jobId.startsWith('seed_job_') &&
    const {'not-found', 'unavailable', 'internal', 'network'}
        .contains(errorCode);

const demoResumeUrl =
    'https://www.w3.org/WAI/WCAG21/Techniques/pdf/pdf-sample.pdf';

List<Job> buildDemoJobs(String providerId, {DateTime? postedAt}) {
  final today = postedAt ?? DateTime.now();
  return [
    Job(
      id: 'seed_job_001',
      providerId: providerId,
      company: 'Google India',
      companyLogo: 'G',
      title: 'Senior Flutter Developer',
      department: 'Mobile Platform',
      location: 'Bangalore',
      workMode: 'Remote',
      minExp: 4,
      maxExp: 8,
      salaryMin: 40,
      salaryMax: 60,
      skills: const ['Flutter', 'Dart', 'Firebase'],
      tags: const ['mobile', 'remote'],
      description: 'Build reliable mobile experiences used at global scale.',
      deadline: '2026-09-30',
      postedAt: today,
      isHot: true,
    ),
    Job(
      id: 'seed_job_002',
      providerId: providerId,
      company: 'Microsoft India',
      companyLogo: 'M',
      title: 'Product Manager, Azure',
      department: 'Cloud',
      location: 'Hyderabad',
      workMode: 'Hybrid',
      minExp: 5,
      maxExp: 10,
      salaryMin: 35,
      salaryMax: 55,
      skills: const ['Product Strategy', 'Azure', 'Analytics'],
      tags: const ['product', 'cloud'],
      description: 'Shape enterprise cloud products for customers in India.',
      deadline: '2026-09-30',
      postedAt: today,
    ),
    Job(
      id: 'seed_job_003',
      providerId: providerId,
      company: 'Amazon India',
      companyLogo: 'A',
      title: 'Software Development Engineer II',
      department: 'Prime',
      location: 'Bangalore',
      workMode: 'On-site',
      minExp: 2,
      maxExp: 6,
      salaryMin: 30,
      salaryMax: 50,
      skills: const ['Java', 'AWS', 'System Design'],
      tags: const ['backend', 'aws'],
      description: 'Own highly available services for Prime customers.',
      deadline: '2026-09-30',
      postedAt: today,
      isHot: true,
    ),
  ];
}

List<AppUser> buildDemoProviders() => [
      AppUser(
        id: 'seed_provider_001',
        role: UserRole.provider,
        name: 'Rahul Sharma',
        headline: 'Engineering Manager at Google India',
        company: 'Google India',
        verified: true,
        orgVerified: true,
        title: 'Engineering Manager',
        location: 'Bangalore',
        experience: 12,
        skills: const ['Flutter', 'Dart', 'System Design'],
        bio: 'I help strong mobile engineers find the right team.',
        profileComplete: 100,
        referralsMade: 42,
        successfulReferrals: 18,
        successRate: 83,
        avgResponseHours: 8,
        responseRate: 0.96,
        gratitudesReceived: 31,
      ),
      AppUser(
        id: 'seed_provider_002',
        role: UserRole.provider,
        name: 'Nisha Verma',
        headline: 'Principal PM at Microsoft India',
        company: 'Microsoft India',
        verified: true,
        orgVerified: true,
        title: 'Principal Product Manager',
        location: 'Hyderabad',
        experience: 11,
        skills: const ['Product Strategy', 'Azure', 'Analytics'],
        bio: 'Happy to refer product leaders for cloud roles.',
        profileComplete: 98,
        referralsMade: 35,
        successfulReferrals: 14,
        successRate: 80,
        avgResponseHours: 12,
        responseRate: 0.92,
        gratitudesReceived: 24,
      ),
      AppUser(
        id: 'seed_provider_003',
        role: UserRole.provider,
        name: 'Arjun Patel',
        headline: 'Senior Engineering Manager at Amazon India',
        company: 'Amazon India',
        verified: true,
        orgVerified: true,
        title: 'Senior Engineering Manager',
        location: 'Bangalore',
        experience: 13,
        skills: const ['Java', 'AWS', 'System Design'],
        bio: 'I review backend and platform profiles for Amazon teams.',
        profileComplete: 96,
        referralsMade: 29,
        successfulReferrals: 11,
        successRate: 76,
        avgResponseHours: 18,
        responseRate: 0.88,
        gratitudesReceived: 19,
      ),
      AppUser(
        id: 'seed_provider_004',
        role: UserRole.provider,
        name: 'Priya Menon',
        headline: 'Design Director at Flipkart',
        company: 'Flipkart',
        verified: true,
        orgVerified: true,
        title: 'Design Director',
        location: 'Bangalore',
        experience: 14,
        skills: const ['Product Design', 'Figma', 'UX Research'],
        bio: 'I refer product designers with strong customer empathy.',
        profileComplete: 95,
        referralsMade: 21,
        successfulReferrals: 9,
        successRate: 79,
        avgResponseHours: 20,
        responseRate: 0.86,
        gratitudesReceived: 16,
      ),
      AppUser(
        id: 'seed_provider_005',
        role: UserRole.provider,
        name: 'Vikram Singh',
        headline: 'Data Science Lead at Razorpay',
        company: 'Razorpay',
        verified: true,
        orgVerified: true,
        title: 'Data Science Lead',
        location: 'Bangalore',
        experience: 10,
        skills: const ['Python', 'Machine Learning', 'SQL'],
        bio: 'Open to referring experienced data and ML candidates.',
        profileComplete: 94,
        referralsMade: 18,
        successfulReferrals: 7,
        successRate: 74,
        avgResponseHours: 24,
        responseRate: 0.82,
        gratitudesReceived: 13,
      ),
      AppUser(
        id: 'seed_provider_006',
        role: UserRole.provider,
        name: 'Sneha Reddy',
        headline: 'Talent Partner at PhonePe',
        company: 'PhonePe',
        verified: true,
        orgVerified: true,
        title: 'Talent Partner',
        location: 'Pune',
        experience: 9,
        skills: const ['Hiring', 'Fintech', 'Leadership'],
        bio: 'I connect experienced candidates with high-growth teams.',
        profileComplete: 92,
        referralsMade: 16,
        successfulReferrals: 6,
        successRate: 72,
        avgResponseHours: 30,
        responseRate: 0.8,
        gratitudesReceived: 11,
      ),
    ];

List<Application> buildDemoSeekerApplications(String seekerId) {
  const statuses = [
    AppStatus.pending,
    AppStatus.underReview,
    AppStatus.strongMatch,
    AppStatus.shortlisted,
    AppStatus.referred,
    AppStatus.interview,
    AppStatus.hired,
    AppStatus.notSelected,
  ];
  const scores = [88, 76, 94, 83, 91, 86, 96, 68];
  final providers = buildDemoProviders();
  return List<Application>.generate(8, (index) {
    final provider = providers[index % providers.length];
    return Application(
      id: 'seed_app_${(index + 1).toString().padLeft(3, '0')}',
      jobId: 'seed_job_${((index % 3) + 1).toString().padLeft(3, '0')}',
      seekerId: seekerId,
      providerId: provider.id,
      status: statuses[index],
      matchScore: scores[index],
      appliedAt: DateTime.now().subtract(Duration(days: index + 1)),
      providerNote: index == 1 ? 'Profile is under team review.' : null,
      strongMatchFlag: scores[index] >= 90,
    );
  });
}

List<AppNotification> buildDemoNotifications(String userId) => [
      AppNotification(
        id: 'seed_notif_001',
        userId: userId,
        type: 'application',
        text: 'Your Google India referral request is under review.',
        actionRoute: '/applications',
      ),
      AppNotification(
        id: 'seed_notif_002',
        userId: userId,
        type: 'match',
        text: 'A new role matches 94% of your profile.',
        actionRoute: '/jobs',
      ),
      AppNotification(
        id: 'seed_notif_003',
        userId: userId,
        type: 'message',
        text: 'Nisha Verma sent an update about your referral.',
        actionRoute: '/messages',
      ),
      AppNotification(
        id: 'seed_notif_004',
        userId: userId,
        type: 'status',
        text: 'Your Microsoft India application was shortlisted.',
        read: true,
        actionRoute: '/applications',
      ),
      AppNotification(
        id: 'seed_notif_005',
        userId: userId,
        type: 'profile',
        text: 'Your profile is ready for referral matching.',
        read: true,
        actionRoute: '/profile',
      ),
    ];

AppUser buildDemoProfile(String userId, {String? email, String? name}) =>
    AppUser(
      id: userId,
      role: UserRole.seeker,
      name: (name == null || name.isEmpty) ? 'Kiran Narla' : name,
      headline: 'Senior Flutter Developer · Open to referrals',
      title: 'Senior Flutter Developer',
      location: 'Bangalore',
      experience: 5,
      skills: const ['Flutter', 'Dart', 'Firebase', 'Figma'],
      preferredRoles: const [
        'Flutter Developer',
        'Mobile Lead',
        'Product Engineer',
      ],
      bio: 'Mobile engineer with five years of product development experience.',
      email: email ?? 'demo@refsure.app',
      resumeUrl: demoResumeUrl,
      activelyLooking: true,
      profileComplete: 90,
      referralsReceived: 8,
    );

List<Message> buildDemoConversation(String userId, String otherId) => [
      Message(
        id: 'seed_message_001',
        fromId: otherId,
        toId: userId,
        text: 'Thanks for sharing your profile. I am reviewing it now.',
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
        read: true,
      ),
      Message(
        id: 'seed_message_002',
        fromId: userId,
        toId: otherId,
        text: 'Thank you. Please let me know if you need any other details.',
        sentAt: DateTime.now().subtract(const Duration(hours: 4)),
        read: true,
      ),
      Message(
        id: 'seed_message_003',
        fromId: otherId,
        toId: userId,
        text:
            'Your experience looks relevant. I will update the referral status.',
        sentAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];

List<AppUser> buildDemoCandidates() => [
      AppUser(
        id: 'seed_candidate_001',
        role: UserRole.seeker,
        name: 'Ananya Rao',
        headline: 'Flutter Engineer',
        title: 'Senior Mobile Engineer',
        location: 'Bangalore',
        experience: 5,
        skills: const ['Flutter', 'Dart', 'Firebase'],
        bio: 'Mobile engineer focused on reliable consumer products.',
        profileComplete: 95,
      ),
      AppUser(
        id: 'seed_candidate_002',
        role: UserRole.seeker,
        name: 'Rohan Mehta',
        headline: 'Product Manager',
        title: 'Product Manager',
        location: 'Hyderabad',
        experience: 7,
        skills: const ['Product Strategy', 'Azure', 'Analytics'],
        bio: 'Enterprise product manager with cloud platform experience.',
        profileComplete: 90,
      ),
      AppUser(
        id: 'seed_candidate_003',
        role: UserRole.seeker,
        name: 'Meera Iyer',
        headline: 'Backend Engineer',
        title: 'Software Engineer II',
        location: 'Bangalore',
        experience: 4,
        skills: const ['Java', 'AWS', 'System Design'],
        bio: 'Backend engineer building distributed services.',
        profileComplete: 88,
      ),
    ];

List<Application> buildDemoProviderApplications(String providerId) => [
      Application(
        id: 'seed_provider_app_001',
        jobId: 'seed_job_001',
        seekerId: 'seed_candidate_001',
        providerId: providerId,
        status: AppStatus.strongMatch,
        matchScore: 94,
      ),
      Application(
        id: 'seed_provider_app_002',
        jobId: 'seed_job_001',
        seekerId: 'seed_candidate_003',
        providerId: providerId,
        status: AppStatus.underReview,
        matchScore: 78,
      ),
      Application(
        id: 'seed_provider_app_003',
        jobId: 'seed_job_002',
        seekerId: 'seed_candidate_002',
        providerId: providerId,
        status: AppStatus.shortlisted,
        matchScore: 89,
      ),
    ];

class AppProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();
  final StorageService _storage = StorageService();
  final OtpService _otp = OtpService();
  final TrustedApplicationService _applications = TrustedApplicationService();
  final TrustedAccountService _account = TrustedAccountService();
  final TrustedGratitudeService _trustedGratitude = TrustedGratitudeService();
  final TrustedSafetyService _safety = TrustedSafetyService();

  AppUser? _currentUser;
  bool _authReady = false;
  bool _loading = false;
  String? _error;
  UserRole _activeRole = UserRole.seeker;
  bool _isAdmin = false;

  List<AppUser> _providers = [];
  List<AppUser> _seekers = [];
  List<Job> _jobs = [];
  List<Application> _myApps = [];
  List<Application> _providerApps = [];
  List<AppNotification> _notifs = [];
  List<Gratitude> _gratitudes = [];
  JobFilter _jobFilter = const JobFilter();

  final List<StreamSubscription<dynamic>> _subs = [];
  final Map<String, int> _applicationVersions = {};
  final Map<String, StreamController<List<Message>>> _demoConversations = {};
  final Map<String, List<Message>> _demoMessages = {};
  Set<String> _blockedUserIds = {};

  AppUser? get currentUser => _currentUser;
  bool get authReady => _authReady;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isSeeker => _activeRole == UserRole.seeker;
  bool get isProvider => _activeRole == UserRole.provider;
  UserRole get activeRole => _activeRole;
  bool get isAdmin => _isAdmin;
  JobFilter get jobFilter => _jobFilter;
  bool isUserBlocked(String userId) => _blockedUserIds.contains(userId);

  /// True when the Firebase user is anonymous (guest / not properly
  /// authenticated). Real email/password or Google users are not guests.
  bool get isGuest => _auth.currentFirebaseUser?.isAnonymous ?? true;

  /// True only when there is no Firebase user at all (fully signed out).
  /// Anonymous demo sessions are NOT signed out.
  bool get isSignedOut => _auth.currentFirebaseUser == null;

  List<AppUser> get providers => _providers;
  List<AppUser> get seekers => _seekers;
  List<Job> get allJobs => _jobs;
  List<Application> get myApplications => _myApps;
  List<Application> get providerApplications => _providerApps;
  List<AppNotification> get notifications => _notifs;
  int get unreadCount => _notifs.where((n) => !n.read).length;
  List<Gratitude> get gratitudes => _gratitudes;

  int get jobsPostedToday {
    final now = DateTime.now();
    return activeJobs
        .where((job) =>
            job.postedAt.year == now.year &&
            job.postedAt.month == now.month &&
            job.postedAt.day == now.day)
        .length;
  }

  List<Job> get activeJobs => _jobs.where((j) => j.status == 'active').toList();

  /// Aggregated counts for the seeker dashboard.
  ///
  /// `total` is every application the seeker has sent. The other buckets
  /// partition that total by lifecycle stage:
  ///   - pending:   awaiting initial action (pending / underReview)
  ///   - open:      moving forward (strongMatch, shortlisted, referred, interview)
  ///   - completed: finalised (hired / notSelected / closed)
  SeekerMetrics get seekerMetrics {
    final apps = _myApps;
    int pending = 0, open = 0, completed = 0;
    for (final a in apps) {
      switch (a.status) {
        case AppStatus.pending:
        case AppStatus.accepted:
        case AppStatus.underReview:
        case AppStatus.needsReview:
          pending++;
        case AppStatus.strongMatch:
        case AppStatus.shortlisted:
        case AppStatus.referred:
        case AppStatus.interview:
          open++;
        case AppStatus.hired:
        case AppStatus.declined:
        case AppStatus.withdrawn:
        case AppStatus.expired:
        case AppStatus.notSelected:
        case AppStatus.closed:
          completed++;
      }
    }
    return SeekerMetrics(
      total: apps.length,
      pending: pending,
      open: open,
      completed: completed,
    );
  }

  List<Job> get filteredJobs {
    var jobs = activeJobs;
    final f = _jobFilter;

    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      jobs = jobs
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.company.toLowerCase().contains(q) ||
              j.skills.any((s) => s.toLowerCase().contains(q)) ||
              j.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    if (f.workMode != null) {
      jobs = jobs.where((j) => j.workMode == f.workMode).toList();
    }
    if (f.location != null) {
      jobs = jobs
          .where((j) =>
              j.location.toLowerCase().contains(f.location!.toLowerCase()) ||
              j.workMode == 'Remote')
          .toList();
    }
    if (f.hotOnly) jobs = jobs.where((j) => j.isHot).toList();
    if (f.todayOnly) {
      final today = DateTime.now();
      jobs = jobs
          .where((j) =>
              j.postedAt.year == today.year &&
              j.postedAt.month == today.month &&
              j.postedAt.day == today.day)
          .toList();
    }
    if (f.last10Days) {
      final cutoff = DateTime.now().subtract(const Duration(days: 10));
      jobs = jobs.where((j) => j.postedAt.isAfter(cutoff)).toList();
    }
    if (f.minExp != null)
      jobs = jobs.where((j) => j.maxExp >= f.minExp!).toList();
    if (f.maxExp != null)
      jobs = jobs.where((j) => j.minExp <= f.maxExp!).toList();
    if (f.tags.isNotEmpty) {
      jobs = jobs.where((j) => f.tags.any((t) => j.tags.contains(t))).toList();
    }

    switch (f.sortBy) {
      case JobSortBy.matchScore:
        if (_currentUser != null) {
          final user = _currentUser!;
          jobs.sort((a, b) => MatchEngine.compute(seeker: user, job: b)
              .score
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

  AppProvider() {
    _init();
  }

  void _init() {
    _subs.add(_auth.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        if (DemoModePolicy.isEnabled) {
          final anon = await _auth.signInAnonymously();
          if (anon.success) return;
        }
        _authReady = true;
        notifyListeners();
        return;
      }

      // Ensure user doc exists (for anonymous or new users)
      // Wrapped in try/catch so _loadUserData always runs even if save fails.
      try {
        final existing = await _db.getUser(firebaseUser.uid);
        if (existing == null) {
          final dummyUser = DemoModePolicy.isEnabled
              ? buildDemoProfile(
                  firebaseUser.uid,
                  email: firebaseUser.email,
                  name: firebaseUser.displayName,
                )
              : AppUser(
                  id: firebaseUser.uid,
                  role: UserRole.seeker,
                  name: firebaseUser.displayName ?? 'User',
                  headline: 'Job Seeker at RefSure',
                  title: 'Software Engineer',
                  location: '',
                  experience: 0,
                  skills: const [],
                  bio: '',
                  email: firebaseUser.email,
                  profileComplete: 30,
                );
          await _db.saveUser(dummyUser);
        }
      } catch (e) {
        debugPrint('[AppProvider._init] profile create error: $e');
        // Continue — _loadUserData will handle the null user case gracefully
      }

      await _loadUserData(firebaseUser.uid);
    }));
  }

  Future<void> _loadUserData(String uid) async {
    _authReady = true;
    _loading = true;
    notifyListeners();
    try {
      _isAdmin = await _auth.hasAdminClaim();
      final demoSession = DemoModePolicy.isEnabled;
      if (demoSession && _jobs.isEmpty) {
        _jobs = buildDemoJobs(uid);
        _providers = buildDemoProviders();
        _myApps = buildDemoSeekerApplications(uid);
        _notifs = buildDemoNotifications(uid);
      }
      _subs.add(_db.watchUser(uid).listen((appUser) {
        if (appUser != null) {
          _currentUser = _withDemoProfile(appUser);
          _activeRole = _currentUser!.role;
          notifyListeners();
        }
      }));
      _subs.add(_db.watchProviders().listen((list) {
        _providers = demoSession && list.isEmpty ? buildDemoProviders() : list;
        notifyListeners();
      }, onError: (Object error) {
        if (demoSession) {
          _providers = buildDemoProviders();
          notifyListeners();
        }
      }));
      _subs.add(_db.watchActiveJobs().listen((list) {
        if (DemoModePolicy.isEnabled) {
          final demoJobs = buildDemoJobs(uid);
          final demoIds = demoJobs.map((job) => job.id).toSet();
          _jobs = [
            ...demoJobs,
            ...list.where((job) => !demoIds.contains(job.id)),
          ];
        } else {
          _jobs = list;
        }
        notifyListeners();
      }, onError: (Object error) {
        if (DemoModePolicy.isEnabled) {
          _jobs = buildDemoJobs(uid);
          notifyListeners();
        }
      }));
      _subs.add(_db.watchNotifications(uid).listen((list) {
        _notifs =
            demoSession && list.isEmpty ? buildDemoNotifications(uid) : list;
        notifyListeners();
      }, onError: (Object error) {
        if (demoSession) {
          _notifs = buildDemoNotifications(uid);
          notifyListeners();
        }
      }));
      _subs.add(_db.watchBlockedUsers(uid).listen((blockedIds) {
        _blockedUserIds = blockedIds;
        notifyListeners();
      }, onError: (Object error) {
        if (demoSession) notifyListeners();
      }));
      _subs.add(_db.watchAllGratitudes().listen((list) {
        _gratitudes = list;
        notifyListeners();
      }));

      final storedUser = await _db.getUser(uid);
      final user = storedUser == null && demoSession
          ? buildDemoProfile(
              uid,
              email: _auth.currentFirebaseUser?.email,
              name: _auth.currentFirebaseUser?.displayName,
            )
          : storedUser;
      if (user != null) {
        // Set _currentUser immediately so profile screen shows without waiting for stream
        _currentUser = _withDemoProfile(user);
        _activeRole = _currentUser!.role;
        notifyListeners();
        if (user.role == UserRole.seeker) {
          _subs.add(_db.watchSeekerApplications(uid).listen((list) {
            _myApps = demoSession && list.isEmpty
                ? buildDemoSeekerApplications(uid)
                : list;
            _hydrateApplicationVersions(_myApps);
            notifyListeners();
          }, onError: (Object error) {
            if (demoSession) {
              _myApps = buildDemoSeekerApplications(uid);
              _hydrateApplicationVersions(_myApps);
              notifyListeners();
            }
          }));
        } else {
          _subs.add(_db.watchProviderApplications(uid).listen((list) {
            _providerApps = list;
            _hydrateApplicationVersions(list);
            notifyListeners();
          }));
          _subs.add(_db.watchSeekers().listen((list) {
            _seekers = list;
            notifyListeners();
          }));
        }
      }
      // Always stop loading after setup, even if user doc missing
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _account.dispose();
    _trustedGratitude.dispose();
    _safety.dispose();
    for (final controller in _demoConversations.values) {
      controller.close();
    }
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _loading = true;
    notifyListeners();
    final r = await _auth.signUpWithEmail(
        email: email, password: password, name: name, role: role);
    _loading = false;
    notifyListeners();
    return r;
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    final r = await _auth.signInWithEmail(email: email, password: password);
    _loading = false;
    notifyListeners();
    return r;
  }

  Future<AuthResult> signInWithGoogle({UserRole role = UserRole.seeker}) async {
    _loading = true;
    notifyListeners();
    final r = await _auth.signInWithGoogle(role: role);
    _loading = false;
    notifyListeners();
    return r;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _isAdmin = false;
    _currentUser = null;
    _blockedUserIds = {};
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    await _db.updateUser(_currentUser!.id, data);
  }

  Future<void> setReferralAvailability({
    required bool available,
    required int weeklyCapacity,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.provider) return;
    final boundedCapacity = weeklyCapacity.clamp(1, 25);
    _currentUser = user.copyWith(
      availableForReferrals: available,
      weeklyReferralCapacity: boundedCapacity,
    );
    notifyListeners();
    if (DemoModePolicy.isEnabled) return;
    await _db.updateUser(user.id, {
      'availableForReferrals': available,
      'weeklyReferralCapacity': boundedCapacity,
    });
  }

  /// Last human-readable profile-save error (null when none).
  String? profileError;

  /// Creates a brand-new Firestore user doc from onboarding data.
  /// Used when the Firebase Auth user exists but no Firestore doc was found.
  /// Returns null on success, or a readable error message on failure.
  /// The local user is set optimistically so the UI never gets stuck on the
  /// "Profile not found" screen even if the Firestore write is slow/blocked.
  Future<String?> createProfile(Map<String, dynamic> data) async {
    profileError = null;
    final uid = _auth.currentUid;
    if (uid == null) {
      profileError = 'You are not signed in. Please retry in a moment.';
      notifyListeners();
      return profileError;
    }
    final email = _auth.currentFirebaseUser?.email ?? '';
    final role = UserRole.values.firstWhere(
      (r) => r.name == (data['role'] as String?),
      orElse: () => UserRole.seeker,
    );
    final user = AppUser(
      id: uid,
      role: role,
      name: data['name'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      title: role == UserRole.provider ? 'Referrer' : 'Job Seeker',
      location: '',
      experience: 0,
      skills: const [],
      bio: '',
      email: data['email'] as String? ?? email,
      company: data['company'] as String?,
      currentCompany: data['currentCompany'] as String?,
      resumeUrl: data['resumeUrl'] as String?,
      profileComplete: (data['profileComplete'] as num?)?.toInt() ?? 50,
      activelyLooking: data['activelyLooking'] as bool? ?? false,
    );
    // Set immediately so the UI shows the dashboard instead of "Profile not
    // found" while the Firestore write completes (or even if it fails).
    _currentUser = user;
    _activeRole = user.role;
    notifyListeners();
    try {
      await _db.saveUser(user);
      return null;
    } catch (e) {
      debugPrint('createProfile save error: $e');
      profileError =
          'Your profile was set locally but could not be saved to the server: $e';
      notifyListeners();
      return profileError;
    }
  }

  /// Switches the user between Job Seeker and Referrer. Persists the new role
  /// to Firestore and rebuilds the role-scoped subscriptions so the rest of
  /// the app sees the right data immediately.
  Future<void> setActiveRole(UserRole role) async {
    if (_currentUser == null || _activeRole == role) return;
    _error = null;
    var localDemoSwitch = false;
    try {
      final result = await _account.changeRole(role);
      _activeRole = result.role;
      _currentUser = _currentUser!.copyWith(role: result.role);
    } on TrustedAccountException catch (error) {
      if (!DemoModePolicy.isEnabled) {
        _error = error.message;
        notifyListeners();
        rethrow;
      }
      // Seeded debug sessions intentionally have no deployed callable. Keep
      // this fallback local; production role changes remain server-authoritative.
      _activeRole = role;
      _currentUser = _currentUser!.copyWith(role: role);
      if (role == UserRole.provider) {
        _seekers = buildDemoCandidates();
        _providerApps = buildDemoProviderApplications(_currentUser!.id);
        _hydrateApplicationVersions(_providerApps);
      }
      localDemoSwitch = true;
    }
    notifyListeners();
    if (localDemoSwitch) return;
    // Tear down role-scoped streams and rebuild for the new role.
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _myApps = [];
    _providerApps = [];
    _gratitudes = [];
    await _loadUserData(_currentUser!.id);
  }

  /// Last human-readable resume-upload error (null when none / cancelled).
  String? resumeError;

  /// Picks + uploads a resume. Returns the URL on success, null on
  /// cancel OR failure. On failure, [resumeError] holds the reason.
  Future<String?> uploadResume() async {
    resumeError = null;
    final uid = _currentUser?.id ?? _auth.currentUid;
    if (uid == null) {
      resumeError = 'You are not signed in yet. Please retry in a moment.';
      return null;
    }
    try {
      final url = await _storage.uploadResumeFile(uid);
      if (url != null && _currentUser != null) {
        await updateProfile({'resumeUrl': url});
      }
      return url;
    } catch (e) {
      if (DemoModePolicy.isEnabled && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(resumeUrl: demoResumeUrl);
        resumeError = null;
        notifyListeners();
        return demoResumeUrl;
      }
      resumeError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Gratitudes ──────────────────────────────────────────────

  /// Whether the current seeker has already thanked [referrerId].
  bool hasThanked(String referrerId) => _gratitudes.any((g) =>
      g.fromSeekerId == _currentUser?.id && g.toReferrerId == referrerId);

  /// Sends a trusted "thank you" command for [referrerId].
  Future<bool> sendGratitude({
    required String referrerId,
    required String message,
  }) async {
    final me = _currentUser;
    if (me == null) return false;
    final result = await _trustedGratitude.sendGratitude(
      providerId: referrerId,
      message: message,
    );
    return !result.idempotent;
  }

  /// Top referrers ordered by [LeaderboardSort]. Pulls from the in-memory
  /// `_providers` list so the home leaderboard updates live with the rest of
  /// the app.
  List<AppUser> leaderboard(LeaderboardSort sort, {int limit = 5}) {
    final list = [..._providers];
    list.sort((a, b) => switch (sort) {
          LeaderboardSort.referrals =>
            b.referralsMade.compareTo(a.referralsMade),
          LeaderboardSort.gratitudes =>
            b.gratitudesReceived.compareTo(a.gratitudesReceived),
        });
    return list.take(limit).toList();
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
    return result;
  }

  bool isOrgEmail(String email) => _otp.isOrgEmail(email);

  // ── Filters ──────────────────────────────────────────────────

  void updateJobFilter(JobFilter filter) {
    _jobFilter = filter;
    notifyListeners();
  }

  /// Sets the work-mode filter. Pass `null` to clear it. Needed because
  /// JobFilter.copyWith uses `??` semantics that can't distinguish between
  /// "leave alone" and "clear to null".
  void setJobWorkMode(String? mode) {
    _jobFilter = JobFilter(
        query: _jobFilter.query,
        workMode: mode,
        location: _jobFilter.location,
        hotOnly: _jobFilter.hotOnly,
        todayOnly: _jobFilter.todayOnly,
        last10Days: _jobFilter.last10Days,
        minExp: _jobFilter.minExp,
        maxExp: _jobFilter.maxExp,
        tags: _jobFilter.tags,
        sortBy: _jobFilter.sortBy);
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
      companyLogo:
          (_currentUser!.company ?? data['company'] ?? 'C')[0].toUpperCase(),
      title: data['title'] ?? '',
      department: data['department'] ?? 'Engineering',
      location: data['location'] ?? '',
      workMode: data['workMode'] ?? 'Hybrid',
      minExp: data['minExp'] ?? 0,
      maxExp: data['maxExp'] ?? 10,
      salaryMin: data['salaryMin'] ?? 0,
      salaryMax: data['salaryMax'] ?? 0,
      skills: List<String>.from(data['skills'] ?? []),
      preferredSkills: List<String>.from(data['preferredSkills'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? '',
      providerNote: data['providerNote'],
      deadline: data['deadline'] ?? '2026-12-31',
      jobRefId: '',
      isHot: data['isHot'] ?? false,
      externalUrl: data['externalUrl'],
    );
    return await _db.postJob(job);
  }

  String importDemoOrganizationJob(ExternalJob externalJob) {
    if (!DemoModePolicy.isEnabled || !isProvider || _currentUser == null) {
      throw StateError('Demo organization import is unavailable.');
    }
    final stableId =
        'seed_org_${externalJob.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
    if (_jobs.any((job) => job.id == stableId)) return stableId;
    _jobs = [
      Job(
        id: stableId,
        providerId: _currentUser!.id,
        company: externalJob.company,
        companyLogo: externalJob.company.isEmpty
            ? '?'
            : externalJob.company[0].toUpperCase(),
        title: externalJob.title,
        department: externalJob.department ?? 'General',
        location: externalJob.location ?? 'Not specified',
        workMode: externalJob.workMode ?? 'Hybrid',
        minExp: 0,
        maxExp: 10,
        skills: const [],
        description: externalJob.description ??
            'Imported from the organization careers portal.',
        deadline: DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String()
            .substring(0, 10),
        postedAt: DateTime.now(),
        jobRefId: externalJob.id,
        source: JobSource.careersPortal,
        externalUrl: externalJob.applyUrl,
      ),
      ..._jobs,
    ];
    notifyListeners();
    return stableId;
  }

  // ── Applications ─────────────────────────────────────────────

  Future<dynamic> applyToJob(Job job) async {
    if (_currentUser == null || !isSeeker) return 'error';
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _applications.submitApplication(jobId: job.id);
      _applicationVersions[result.applicationId] = result.version;
      return result.idempotent ? 'already' : true;
    } on TrustedApplicationException catch (error) {
      if (shouldUseDemoReferralFallback(
        demoMode: DemoModePolicy.isEnabled,
        jobId: job.id,
        errorCode: error.code,
      )) {
        final applicationId = 'demo:${_currentUser!.id}:${job.id}';
        if (_myApps.any((application) => application.id == applicationId)) {
          return 'already';
        }
        final application = Application(
          id: applicationId,
          jobId: job.id,
          seekerId: _currentUser!.id,
          providerId: job.providerId,
          matchScore: 0,
        );
        _myApps = [..._myApps, application];
        _applicationVersions[applicationId] = application.version;
        return true;
      }
      _error = error.message;
      return error.code == 'already-exists' ? 'already' : 'error';
    } on Object catch (error) {
      _error = 'Could not request referral: $error';
      return 'error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApplicationStatus(
    String appId,
    AppStatus status, {
    String? note,
    String? receiptReference,
    int? expectedVersion,
  }) async {
    final hydratedVersion = [..._myApps, ..._providerApps]
        .where((application) => application.id == appId)
        .map((application) => application.version)
        .firstOrNull;
    final version =
        expectedVersion ?? hydratedVersion ?? _applicationVersions[appId] ?? 1;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _applications.transitionApplication(
        applicationId: appId,
        expectedVersion: version,
        toStatus: status,
        note: note,
        receiptReference: receiptReference,
      );
      _applicationVersions[appId] = result.version;
      return true;
    } on TrustedApplicationException catch (error) {
      if (DemoModePolicy.isEnabled && appId.startsWith('seed_')) {
        final providerApplication = appId.startsWith('seed_provider_app_');
        final source = providerApplication ? _providerApps : _myApps;
        final updated = source
            .map((application) => application.id == appId
                ? application.copyWith(
                    status: status,
                    providerNote: note,
                    declineReason: status == AppStatus.declined ? note : null,
                    referralReceiptId:
                        status == AppStatus.referred ? appId : null,
                    respondedAt: const {
                      AppStatus.accepted,
                      AppStatus.declined,
                    }.contains(status)
                        ? DateTime.now()
                        : null,
                    version: application.version + 1,
                  )
                : application)
            .toList();
        if (providerApplication) {
          _providerApps = updated;
        } else {
          _myApps = updated;
        }
        _applicationVersions[appId] = version + 1;
        return true;
      }
      _error = error.message;
      return false;
    } on Object catch (error) {
      _error = 'Could not update referral request: $error';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _hydrateApplicationVersions(List<Application> applications) {
    for (final application in applications) {
      _applicationVersions[application.id] = application.version;
    }
  }

  // ── Match ─────────────────────────────────────────────────────

  MatchReport computeMatch(Job job) {
    if (_currentUser == null) {
      return MatchReport(
          score: 0,
          band: MatchBand.lowMatch,
          bandLabel: 'Low Match',
          recommendation: 'Sign in to see your match.',
          matchedSkills: [],
          missingSkills: job.skills,
          strengths: [],
          gaps: [],
          skillScore: 0,
          experienceScore: 0,
          locationScore: 0,
          contextScore: 0);
    }
    return MatchEngine.compute(seeker: _currentUser!, job: job);
  }

  MatchReport computeMatchForSeeker(AppUser seeker, Job job) =>
      MatchEngine.compute(seeker: seeker, job: job);

  // ── Messaging ────────────────────────────────────────────────

  Stream<List<Message>> watchConversation(String otherId) {
    if (_currentUser == null) return Stream.value([]);
    if (DemoModePolicy.isEnabled && otherId.startsWith('seed_')) {
      final messages = _demoMessages.putIfAbsent(
        otherId,
        () => buildDemoConversation(_currentUser!.id, otherId),
      );
      final controller = _demoConversations.putIfAbsent(
        otherId,
        () => StreamController<List<Message>>.broadcast(),
      );
      return Stream<List<Message>>.multi((listener) {
        listener.add(List<Message>.unmodifiable(messages));
        final subscription = controller.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });
    }
    return _db.watchConversation(_currentUser!.id, otherId);
  }

  Future<void> sendMessage(String toId, String text) async {
    if (_currentUser == null) return;
    if (isUserBlocked(toId)) {
      throw const TrustedSafetyException(
        'failed-precondition',
        'Unblock this user before sending a message.',
      );
    }
    if (DemoModePolicy.isEnabled && toId.startsWith('seed_')) {
      final messages = _demoMessages.putIfAbsent(
        toId,
        () => buildDemoConversation(_currentUser!.id, toId),
      );
      messages.add(Message(
        id: 'demo_message_${messages.length + 1}',
        fromId: _currentUser!.id,
        toId: toId,
        text: text,
      ));
      _demoConversations[toId]?.add(List<Message>.unmodifiable(messages));
      return;
    }
    await _db.sendMessage(
        Message(id: '', fromId: _currentUser!.id, toId: toId, text: text));
  }

  Future<void> blockUser(String userId) async {
    final uid = _currentUser?.id;
    if (uid == null || uid == userId) return;
    _blockedUserIds = {..._blockedUserIds, userId};
    notifyListeners();
    if (DemoModePolicy.isEnabled && userId.startsWith('seed_')) return;
    await _db.blockUser(uid, userId);
  }

  Future<void> unblockUser(String userId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _blockedUserIds = {..._blockedUserIds}..remove(userId);
    notifyListeners();
    if (DemoModePolicy.isEnabled && userId.startsWith('seed_')) return;
    await _db.unblockUser(uid, userId);
  }

  Future<String?> reportUser({
    required String userId,
    required String category,
    required String details,
  }) async {
    if (_currentUser == null || userId == _currentUser!.id) {
      return 'This user cannot be reported.';
    }
    if (DemoModePolicy.isEnabled && userId.startsWith('seed_')) return null;
    try {
      await _safety.reportUser(
        targetId: userId,
        category: category,
        details: details,
        contextId: 'conversation:$userId',
      );
      return null;
    } on TrustedSafetyException catch (error) {
      return error.message;
    }
  }

  // ── Notifications ────────────────────────────────────────────

  Future<void> markAllNotifsRead() async {
    if (_currentUser == null) return;
    if (DemoModePolicy.isEnabled &&
        _notifs.any((notification) => notification.id.startsWith('seed_'))) {
      _notifs = _notifs
          .map((notification) => AppNotification(
                id: notification.id,
                userId: notification.userId,
                type: notification.type,
                text: notification.text,
                read: true,
                createdAt: notification.createdAt,
                actionRoute: notification.actionRoute,
              ))
          .toList();
      notifyListeners();
      return;
    }
    await _db.markAllNotifsRead(_currentUser!.id);
  }

  Future<void> markNotifRead(String id) async {
    if (DemoModePolicy.isEnabled && id.startsWith('seed_')) {
      _notifs = _notifs
          .map((notification) => notification.id == id
              ? AppNotification(
                  id: notification.id,
                  userId: notification.userId,
                  type: notification.type,
                  text: notification.text,
                  read: true,
                  createdAt: notification.createdAt,
                  actionRoute: notification.actionRoute,
                )
              : notification)
          .toList();
      notifyListeners();
      return;
    }
    await _db.markNotifRead(id);
  }

  // ── Helpers ──────────────────────────────────────────────────

  AppUser? findUser(String id) {
    try {
      return [..._providers, ..._seekers].firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  AppUser _withDemoProfile(AppUser user) {
    if (!DemoModePolicy.isEnabled ||
        !(_auth.currentFirebaseUser?.isAnonymous == true ||
            user.email == 'demo@refsure.app')) {
      return user;
    }
    final demo = buildDemoProfile(
      user.id,
      email: user.email,
      name: user.name,
    );
    return user.copyWith(
      name: demo.name,
      headline: demo.headline,
      title: demo.title,
      location: demo.location,
      experience: demo.experience,
      skills: demo.skills,
      preferredRoles: demo.preferredRoles,
      bio: demo.bio,
      activelyLooking: true,
      profileComplete: 90,
      resumeUrl: user.resumeUrl ?? demo.resumeUrl,
    );
  }

  Job? findJob(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── JobFilter ─────────────────────────────────────────────────

class JobFilter {
  final String query;
  final String? workMode;
  final String? location;
  final bool hotOnly;
  final bool todayOnly;
  final bool last10Days;
  final int? minExp;
  final int? maxExp;
  final List<String> tags;
  final JobSortBy sortBy;

  const JobFilter({
    this.query = '',
    this.workMode,
    this.location,
    this.hotOnly = false,
    this.todayOnly = false,
    this.last10Days = false,
    this.minExp,
    this.maxExp,
    this.tags = const [],
    this.sortBy = JobSortBy.matchScore,
  });

  JobFilter copyWith({
    String? query,
    String? workMode,
    String? location,
    bool? hotOnly,
    bool? todayOnly,
    bool? last10Days,
    int? minExp,
    int? maxExp,
    List<String>? tags,
    JobSortBy? sortBy,
  }) =>
      JobFilter(
        query: query ?? this.query,
        workMode: workMode ?? this.workMode,
        location: location ?? this.location,
        hotOnly: hotOnly ?? this.hotOnly,
        todayOnly: todayOnly ?? this.todayOnly,
        last10Days: last10Days ?? this.last10Days,
        minExp: minExp ?? this.minExp,
        maxExp: maxExp ?? this.maxExp,
        tags: tags ?? this.tags,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isActive =>
      query.isNotEmpty ||
      workMode != null ||
      location != null ||
      hotOnly ||
      todayOnly ||
      last10Days ||
      minExp != null ||
      maxExp != null ||
      tags.isNotEmpty;

  int get activeCount {
    int n = 0;
    if (query.isNotEmpty) n++;
    if (workMode != null) n++;
    if (location != null) n++;
    if (hotOnly) n++;
    if (todayOnly || last10Days) n++;
    if (minExp != null || maxExp != null) n++;
    n += tags.length;
    return n;
  }
}

/// Seeker dashboard counts — see [AppProvider.seekerMetrics].
class SeekerMetrics {
  final int total;
  final int pending;
  final int open;
  final int completed;
  const SeekerMetrics({
    required this.total,
    required this.pending,
    required this.open,
    required this.completed,
  });
}
