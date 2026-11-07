// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/enums/enums.dart';

class Job {
  final String id;
  final String providerId;
  final String company;
  final String companyLogo;
  final String title;
  final String department;
  final String location;
  final String workMode;
  final int minExp, maxExp;
  final int salaryMin, salaryMax;
  final List<String> skills;
  final List<String> preferredSkills;
  final List<String> tags;
  final String description;
  final String? providerNote;
  final String status;
  final int applicants;
  final int viewCount;
  final String deadline;
  final DateTime postedAt;
  final String jobRefId;
  final bool isHot;
  final JobSource source;
  final String? externalUrl;

  Job({
    required this.id,
    required this.providerId,
    required this.company,
    required this.companyLogo,
    required this.title,
    required this.department,
    required this.location,
    required this.workMode,
    required this.minExp,
    required this.maxExp,
    this.salaryMin = 0,
    this.salaryMax = 0,
    required this.skills,
    this.preferredSkills = const [],
    this.tags = const [],
    required this.description,
    this.providerNote,
    this.status = 'active',
    this.applicants = 0,
    this.viewCount = 0,
    required this.deadline,
    DateTime? postedAt,
    this.jobRefId = '',
    this.isHot = false,
    this.source = JobSource.manual,
    this.externalUrl,
  }) : postedAt = postedAt ?? DateTime.now();

  bool get isNew => DateTime.now().difference(postedAt).inDays <= 1;
  bool get isRecent => DateTime.now().difference(postedAt).inDays <= 10;

  Map<String, dynamic> toFirestore() => {
    'providerId': providerId, 'company': company, 'companyLogo': companyLogo,
    'title': title, 'department': department, 'location': location,
    'workMode': workMode, 'minExp': minExp, 'maxExp': maxExp,
    'salaryMin': salaryMin, 'salaryMax': salaryMax, 'skills': skills,
    'preferredSkills': preferredSkills, 'tags': tags, 'description': description,
    'providerNote': providerNote, 'status': status, 'applicants': applicants,
    'viewCount': viewCount, 'deadline': deadline, 'postedAt': Timestamp.fromDate(postedAt),
    'jobRefId': jobRefId, 'isHot': isHot, 'source': source.name,
    'externalUrl': externalUrl,
  };

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      providerId: d['providerId'] ?? '',
      company: d['company'] ?? '',
      companyLogo: d['companyLogo'] ?? 'C',
      title: d['title'] ?? '',
      department: d['department'] ?? '',
      location: d['location'] ?? '',
      workMode: d['workMode'] ?? 'Hybrid',
      minExp: d['minExp'] ?? 0,
      maxExp: d['maxExp'] ?? 10,
      salaryMin: d['salaryMin'] ?? 0,
      salaryMax: d['salaryMax'] ?? 0,
      skills: List<String>.from(d['skills'] ?? []),
      preferredSkills: List<String>.from(d['preferredSkills'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      description: d['description'] ?? '',
      providerNote: d['providerNote'],
      status: d['status'] ?? 'active',
      applicants: d['applicants'] ?? 0,
      viewCount: d['viewCount'] ?? 0,
      deadline: d['deadline'] ?? '',
      postedAt: (d['postedAt'] as Timestamp?)?.toDate(),
      jobRefId: d['jobRefId'] ?? '',
      isHot: d['isHot'] ?? false,
      source: JobSource.values.firstWhere(
        (s) => s.name == (d['source'] ?? 'manual'), orElse: () => JobSource.manual),
      externalUrl: d['externalUrl'],
    );
  }

  Job copyWith({int? applicants, String? status, int? viewCount}) => Job(
    id: id, providerId: providerId, company: company, companyLogo: companyLogo,
    title: title, department: department, location: location, workMode: workMode,
    minExp: minExp, maxExp: maxExp, salaryMin: salaryMin, salaryMax: salaryMax,
    skills: skills, preferredSkills: preferredSkills, tags: tags, description: description,
    providerNote: providerNote, status: status ?? this.status,
    applicants: applicants ?? this.applicants, viewCount: viewCount ?? this.viewCount,
    deadline: deadline, postedAt: postedAt, jobRefId: jobRefId,
    isHot: isHot, source: source, externalUrl: externalUrl,
  );
}
