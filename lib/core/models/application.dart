// ignore_for_file: argument_type_not_assignable, cast_nullable_to_non_nullable, always_put_required_named_parameters_first, sort_constructors_first, require_trailing_commas, unreachable_switch_case

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/match_report.dart';

class Application {
  final String id;
  final String jobId;
  final String seekerId;
  final String providerId;
  final AppStatus status;
  final int matchScore;
  final MatchReport? matchReport;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final DateTime? viewedAt;
  final String? providerNote;
  final bool strongMatchFlag;

  Application({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.providerId,
    this.status = AppStatus.pending,
    required this.matchScore,
    this.matchReport,
    DateTime? appliedAt,
    DateTime? updatedAt,
    this.viewedAt,
    this.providerNote,
    this.strongMatchFlag = false,
  })  : appliedAt = appliedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusLabel => switch (status) {
    AppStatus.pending       => 'Pending',
    AppStatus.underReview   => 'Under Review',
    AppStatus.strongMatch   => 'Strong Match',
    AppStatus.needsReview   => 'Needs Review',
    AppStatus.shortlisted   => 'Shortlisted',
    AppStatus.referred      => 'Referred',
    AppStatus.interview     => 'Interview',
    AppStatus.hired         => 'Hired',
    AppStatus.notSelected   => 'Not Selected',
    AppStatus.closed        => 'Position Closed',
    _ => 'Pending',
  };

  String get statusKey => status.name;

  Map<String, dynamic> toFirestore() => {
    'jobId': jobId, 'seekerId': seekerId, 'providerId': providerId,
    'status': status.name, 'matchScore': matchScore,
    'matchReport': matchReport?.toMap(),
    'appliedAt': Timestamp.fromDate(appliedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
    'providerNote': providerNote,
    'strongMatchFlag': strongMatchFlag,
  };

  factory Application.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      jobId: d['jobId'] ?? '',
      seekerId: d['seekerId'] ?? '',
      providerId: d['providerId'] ?? '',
      status: AppStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'pending'),
        orElse: () => AppStatus.pending),
      matchScore: d['matchScore'] ?? 0,
      matchReport: d['matchReport'] != null
          ? MatchReport.fromMap(Map<String, dynamic>.from(d['matchReport']))
          : null,
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      viewedAt:  (d['viewedAt']  as Timestamp?)?.toDate(),
      providerNote: d['providerNote'],
      strongMatchFlag: d['strongMatchFlag'] ?? false,
    );
  }

  Application copyWith({
    AppStatus? status, String? providerNote, DateTime? viewedAt}) =>
    Application(
      id: id, jobId: jobId, seekerId: seekerId, providerId: providerId,
      status: status ?? this.status, matchScore: matchScore,
      matchReport: matchReport, appliedAt: appliedAt, updatedAt: DateTime.now(),
      viewedAt: viewedAt ?? this.viewedAt, providerNote: providerNote ?? this.providerNote,
      strongMatchFlag: strongMatchFlag);
}
