// lib/features/cv_job_matcher/models/extracted_profile.dart
//
// Represents a structured profile parsed from free-form CV text.
// Keeps raw text alongside extracted fields so the engine can
// fall back to full-text analysis when structured data is sparse.

class ExtractedProfile {
  const ExtractedProfile({
    required this.rawText,
    this.name,
    this.currentTitle,
    this.experienceYears,
    this.skills = const [],
    this.tools = const [],
    this.domains = const [],
    this.education = const [],
    this.certifications = const [],
    this.jobTitlesHeld = const [],
    this.responsibilities = const [],
    this.industries = const [],
  });

  final String rawText;
  final String? name;
  final String? currentTitle;
  final int? experienceYears;
  final List<String> skills;
  final List<String> tools;
  final List<String> domains;
  final List<String> education;
  final List<String> certifications;
  final List<String> jobTitlesHeld;
  final List<String> responsibilities;
  final List<String> industries;

  bool get isEmpty => rawText.trim().isEmpty;

  ExtractedProfile copyWith({
    String? currentTitle,
    int? experienceYears,
    List<String>? skills,
    List<String>? tools,
    List<String>? domains,
    List<String>? industries,
  }) =>
      ExtractedProfile(
        rawText: rawText,
        name: name,
        currentTitle: currentTitle ?? this.currentTitle,
        experienceYears: experienceYears ?? this.experienceYears,
        skills: skills ?? this.skills,
        tools: tools ?? this.tools,
        domains: domains ?? this.domains,
        education: education,
        certifications: certifications,
        jobTitlesHeld: jobTitlesHeld,
        responsibilities: responsibilities,
        industries: industries ?? this.industries,
      );
}
