// lib/features/cv_job_matcher/models/job_opening.dart
//
// Represents a job fetched from a company's career source
// (API, Workday, Greenhouse, Lever, Naukri, or mock).
// Distinct from the platform's own Job model — this is the raw
// external listing that a provider SELECTS and then posts.

class JobOpening {
  const JobOpening({
    required this.id,
    required this.companyName,
    required this.title,
    required this.location,
    required this.country,
    required this.description,
    this.responsibilities = const [],
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.experienceMin = 0,
    this.experienceMax = 10,
    this.workMode = 'Hybrid',
    this.department = '',
    this.salaryRange = '',
    this.postedDate,
    this.sourceUrl,
    this.sourcePlatform = 'manual',
    this.isAlreadyPosted = false,
  });

  final String id;
  final String companyName;
  final String title;
  final String location;
  final String country;
  final String description;
  final List<String> responsibilities;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final int experienceMin;
  final int experienceMax;
  final String workMode;
  final String department;
  final String salaryRange;
  final DateTime? postedDate;
  final String? sourceUrl;
  final String sourcePlatform;

  /// True when this opening has already been posted by this provider.
  final bool isAlreadyPosted;

  /// Full JD text used by the matching engine.
  String get fullJdText =>
      '$title\n\n$description\n\n'
      '${responsibilities.isNotEmpty ? "Responsibilities:\n${responsibilities.join("\n")}" : ""}\n\n'
      '${requiredSkills.isNotEmpty ? "Required Skills: ${requiredSkills.join(", ")}" : ""}\n\n'
      '${preferredSkills.isNotEmpty ? "Preferred Skills: ${preferredSkills.join(", ")}" : ""}';

  JobOpening copyWith({bool? isAlreadyPosted}) => JobOpening(
    id: id,
    companyName: companyName,
    title: title,
    location: location,
    country: country,
    description: description,
    responsibilities: responsibilities,
    requiredSkills: requiredSkills,
    preferredSkills: preferredSkills,
    experienceMin: experienceMin,
    experienceMax: experienceMax,
    workMode: workMode,
    department: department,
    salaryRange: salaryRange,
    postedDate: postedDate,
    sourceUrl: sourceUrl,
    sourcePlatform: sourcePlatform,
    isAlreadyPosted: isAlreadyPosted ?? this.isAlreadyPosted,
  );
}
