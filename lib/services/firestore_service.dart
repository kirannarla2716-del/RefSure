// lib/services/firestore_service.dart — v2.0
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users      => _db.collection('users');
  CollectionReference get _jobs       => _db.collection('jobs');
  CollectionReference get _apps       => _db.collection('applications');
  CollectionReference get _msgs       => _db.collection('messages');
  CollectionReference get _notifs     => _db.collection('notifications');
  CollectionReference get _gratitudes => _db.collection('gratitudes');

  // ─────────────────── USERS ──────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  Stream<AppUser?> watchUser(String uid) =>
      _users.doc(uid).snapshots()
          .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

  Future<void> saveUser(AppUser user) =>
      _users.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));

  Future<void> markOrgVerified(String uid, String orgEmail, String companyName) =>
      _users.doc(uid).update({
        'orgVerified': true,
        'orgEmail': orgEmail,
        'company': companyName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Providers ordered by trust score + referrals
  Stream<List<AppUser>> watchProviders() =>
      _users.where('role', isEqualTo: 'provider')
          .orderBy('trustScore', descending: true)
          .snapshots()
          .map((s) => s.docs.map(AppUser.fromFirestore).toList());

  /// Seekers ordered by profile completeness
  Stream<List<AppUser>> watchSeekers() =>
      _users.where('role', isEqualTo: 'seeker')
          .orderBy('profileComplete', descending: true)
          .snapshots()
          .map((s) => s.docs.map(AppUser.fromFirestore).toList());

  // ─────────────────── JOBS ───────────────────────────────

  Stream<List<Job>> watchActiveJobs() =>
      _jobs.where('status', isEqualTo: 'active')
          .orderBy('postedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Job.fromFirestore).toList());

  /// Hot jobs first, then recency
  Stream<List<Job>> watchHotJobs() =>
      _jobs.where('status', isEqualTo: 'active')
          .where('isHot', isEqualTo: true)
          .orderBy('postedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Job.fromFirestore).toList());

  Stream<List<Job>> watchProviderJobs(String providerId) =>
      _jobs.where('providerId', isEqualTo: providerId)
          .orderBy('postedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Job.fromFirestore).toList());

  Future<Job?> getJob(String jobId) async {
    final doc = await _jobs.doc(jobId).get();
    return doc.exists ? Job.fromFirestore(doc) : null;
  }

  Future<String> postJob(Job job) async {
    final ref = _jobs.doc();
    await ref.set({
      ...job.toFirestore(), 'id': ref.id,
      'postedAt': FieldValue.serverTimestamp(),
    });
    // Increment provider's totalJobsPosted
    await _users.doc(job.providerId).update({
      'totalJobsPosted': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateJobStatus(String jobId, String status) =>
      _jobs.doc(jobId).update({'status': status});

  Future<void> incrementJobView(String jobId) =>
      _jobs.doc(jobId).update({'viewCount': FieldValue.increment(1)});

  Future<void> incrementApplicants(String jobId) =>
      _jobs.doc(jobId).update({'applicants': FieldValue.increment(1)});

  // ─────────────────── APPLICATIONS ───────────────────────

  Stream<List<Application>> watchSeekerApplications(String seekerId) =>
      _apps.where('seekerId', isEqualTo: seekerId)
          .orderBy('appliedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Application.fromFirestore).toList());

  Stream<List<Application>> watchJobApplications(String jobId) =>
      _apps.where('jobId', isEqualTo: jobId)
          .orderBy('matchScore', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Application.fromFirestore).toList());

  Stream<List<Application>> watchProviderApplications(String providerId) =>
      _apps.where('providerId', isEqualTo: providerId)
          .orderBy('matchScore', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Application.fromFirestore).toList());

  Future<bool> hasApplied(String jobId, String seekerId) async {
    final snap = await _apps
        .where('jobId', isEqualTo: jobId)
        .where('seekerId', isEqualTo: seekerId)
        .limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<String> submitApplication(Application app) async {
    final ref = _apps.doc();
    await ref.set({...app.toFirestore(), 'id': ref.id});
    await incrementApplicants(app.jobId);
    return ref.id;
  }

  Future<void> updateApplicationStatus(
    String appId, AppStatus status, {String? note}) async {
    final update = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (note != null) update['providerNote'] = note;

    // Mark viewedAt on first provider interaction
    if (status == AppStatus.underReview) {
      update['viewedAt'] = FieldValue.serverTimestamp();
    }
    await _apps.doc(appId).update(update);

    // Track successful referrals
    if (status == AppStatus.referred || status == AppStatus.hired) {
      final app = Application.fromFirestore(await _apps.doc(appId).get());
      await _users.doc(app.providerId).update({
        'referralsMade': FieldValue.increment(1),
        if (status == AppStatus.hired) 'successfulReferrals': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─────────────────── MESSAGES ───────────────────────────

  Stream<List<Message>> watchConversation(String uid1, String uid2) =>
      _db.collection('messages')
          .where(Filter.or(
            Filter.and(Filter('fromId', isEqualTo: uid1), Filter('toId', isEqualTo: uid2)),
            Filter.and(Filter('fromId', isEqualTo: uid2), Filter('toId', isEqualTo: uid1)),
          ))
          .orderBy('sentAt')
          .snapshots()
          .map((s) => s.docs.map(Message.fromFirestore).toList());

  Future<void> sendMessage(Message msg) => _msgs.add(msg.toFirestore());

  // ─────────────────── GRATITUDES ─────────────────────────

  /// All gratitudes received by [referrerId], newest first.
  Stream<List<Gratitude>> watchGratitudesFor(String referrerId) =>
      _gratitudes.where('toReferrerId', isEqualTo: referrerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Gratitude.fromFirestore).toList());

  /// All gratitudes (used for the leaderboard view).
  Stream<List<Gratitude>> watchAllGratitudes() =>
      _gratitudes.orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Gratitude.fromFirestore).toList());

  /// True if [seekerId] has already thanked [referrerId] — used to keep the
  /// "Send thanks" CTA idempotent per relationship.
  Future<bool> hasThanked(String seekerId, String referrerId) async {
    final snap = await _gratitudes
        .where('fromSeekerId', isEqualTo: seekerId)
        .where('toReferrerId', isEqualTo: referrerId)
        .limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Adds a gratitude doc and increments the referrer's counter atomically.
  Future<void> addGratitude(Gratitude g) async {
    final batch = _db.batch();
    final ref = _gratitudes.doc();
    batch.set(ref, {...g.toFirestore(), 'id': ref.id});
    batch.update(_users.doc(g.toReferrerId), {
      'gratitudesReceived': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ─────────────────── NOTIFICATIONS ──────────────────────

  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _notifs.where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map(AppNotification.fromFirestore).toList());

  Future<void> createNotification(AppNotification n) =>
      _notifs.add(n.toFirestore());

  Future<void> markNotifRead(String id) =>
      _notifs.doc(id).update({'read': true});

  Future<void> markAllNotifsRead(String userId) async {
    final snap = await _notifs
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) batch.update(d.reference, {'read': true});
    await batch.commit();
  }

  // ─────────────────── SEED DATA ──────────────────────────

  Future<void> seedSampleJobs() async {
    final existing = await _jobs.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final job in _sampleJobs) {
      final ref = _jobs.doc();
      batch.set(ref, {...job, 'postedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  static const _sampleJobs = [
    {
      'providerId': 'seed', 'company': 'Google', 'companyLogo': 'G',
      'title': 'Software Engineer III', 'department': 'Infrastructure',
      'location': 'Bangalore', 'workMode': 'Hybrid', 'minExp': 3, 'maxExp': 7,
      'salaryMin': 40, 'salaryMax': 80, 'status': 'active', 'applicants': 0, 'viewCount': 0,
      'skills': ['Go', 'Python', 'Kubernetes', 'Distributed Systems'],
      'preferredSkills': ['GCP', 'gRPC'], 'tags': ['backend', 'infra'],
      'description': 'Join Google Infrastructure to build distributed systems at planetary scale. '
          'You will design and build robust, scalable services used by billions of users. '
          'Strong system design and distributed systems background is essential.',
      'deadline': '2026-06-30', 'jobRefId': '', 'isHot': true,
      'source': 'manual', 'externalUrl': null, 'providerNote': null,
    },
    {
      'providerId': 'seed', 'company': 'Microsoft', 'companyLogo': 'M',
      'title': 'Senior Product Manager', 'department': 'Azure',
      'location': 'Hyderabad', 'workMode': 'Hybrid', 'minExp': 5, 'maxExp': 12,
      'salaryMin': 35, 'salaryMax': 70, 'status': 'active', 'applicants': 0, 'viewCount': 0,
      'skills': ['Product Strategy', 'SQL', 'Data Analysis', 'Azure'],
      'preferredSkills': ['Enterprise Sales', 'Agile'], 'tags': ['product', 'cloud'],
      'description': 'Drive product strategy for Azure enterprise offerings in India. '
          'You will work with engineering and sales teams to define roadmap and GTM strategy. '
          'Strong analytical skills and enterprise product experience required.',
      'deadline': '2026-06-15', 'jobRefId': '', 'isHot': false,
      'source': 'manual', 'externalUrl': null, 'providerNote': null,
    },
    {
      'providerId': 'seed', 'company': 'Amazon', 'companyLogo': 'A',
      'title': 'SDE-2', 'department': 'Prime', 'location': 'Bangalore',
      'workMode': 'On-site', 'minExp': 2, 'maxExp': 6,
      'salaryMin': 30, 'salaryMax': 55, 'status': 'active', 'applicants': 0, 'viewCount': 0,
      'skills': ['Java', 'AWS', 'Spring Boot', 'System Design'],
      'preferredSkills': ['Kafka', 'DynamoDB'], 'tags': ['java', 'aws', 'backend'],
      'description': 'Build the Prime membership platform serving 300M+ customers. '
          'You will own critical backend services with high availability requirements. '
          'Experience with Java microservices and AWS is required.',
      'deadline': '2026-05-30', 'jobRefId': '', 'isHot': true,
      'source': 'manual', 'externalUrl': null, 'providerNote': null,
    },
  ];
}
