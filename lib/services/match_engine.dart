// lib/services/match_engine.dart
// Intelligent contextual JD vs CV match engine v2.0
// Uses skill synonyms, title relevance, semantic keyword density,
// experience gap analysis, and location compatibility.

import '../models/models.dart';

// ─────────────────────────────────────────────────────────────
// SKILL SYNONYM MAP
// Normalises equivalent skill names before comparing
// ─────────────────────────────────────────────────────────────
const Map<String, List<String>> _skillAliases = {
  'javascript': ['js', 'javascript', 'es6', 'es2015', 'ecmascript'],
  'typescript': ['ts', 'typescript'],
  'react':      ['react', 'reactjs', 'react.js'],
  'node':       ['node', 'nodejs', 'node.js'],
  'python':     ['python', 'python3', 'py'],
  'java':       ['java', 'core java', 'java8', 'java11'],
  'kubernetes': ['kubernetes', 'k8s'],
  'aws':        ['aws', 'amazon web services', 'amazon aws'],
  'gcp':        ['gcp', 'google cloud', 'google cloud platform'],
  'azure':      ['azure', 'microsoft azure'],
  'sql':        ['sql', 'mysql', 'postgresql', 'postgres', 'mssql'],
  'mongodb':    ['mongodb', 'mongo'],
  'docker':     ['docker', 'container', 'containerization'],
  'git':        ['git', 'github', 'gitlab', 'version control'],
  'machine learning': ['ml', 'machine learning', 'deep learning', 'ai'],
  'flutter':    ['flutter', 'dart flutter'],
  'spring':     ['spring', 'spring boot', 'spring framework'],
  'react native': ['react native', 'rn', 'react-native'],
  'data analysis': ['data analysis', 'data analytics', 'analytics'],
  'system design': ['system design', 'distributed systems', 'architecture'],
};

// ─────────────────────────────────────────────────────────────
// TITLE RELEVANCE MAP
// Job title → related skills it implies competence in
// ─────────────────────────────────────────────────────────────
const Map<String, List<String>> _titleImpliedSkills = {
  'software engineer': ['coding', 'system design', 'git', 'debugging'],
  'frontend':  ['javascript', 'react', 'css', 'html'],
  'backend':   ['api', 'database', 'sql', 'server'],
  'fullstack': ['javascript', 'react', 'node', 'sql'],
  'data scientist': ['python', 'machine learning', 'sql', 'statistics'],
  'devops':    ['kubernetes', 'docker', 'aws', 'ci/cd'],
  'product manager': ['product strategy', 'agile', 'roadmap', 'stakeholder'],
  'data engineer': ['python', 'sql', 'etl', 'spark'],
  'android':   ['android', 'kotlin', 'java'],
  'ios':       ['ios', 'swift', 'objective-c'],
};

// ─────────────────────────────────────────────────────────────
// MATCH ENGINE
// ─────────────────────────────────────────────────────────────
class MatchEngine {
  static MatchReport compute({
    required AppUser seeker,
    required Job job,
  }) {
    final seekerSkillsNorm  = _normalizeSkills(seeker.skills);
    final jobRequiredNorm   = _normalizeSkills(job.skills);
    final jobPreferredNorm  = _normalizeSkills(job.preferredSkills);
    final titleNorm         = seeker.title.toLowerCase();
    final jobDescLower      = job.description.toLowerCase();

    // ── 1. Skill score (40 pts) ────────────────────────────
    final matched   = <String>[];
    final missing   = <String>[];
    int skillHits   = 0;

    for (final reqSkill in job.skills) {
      final norm = _normalizeOne(reqSkill);
      if (_skillMatches(norm, seekerSkillsNorm)) {
        skillHits++;
        matched.add(reqSkill);
      } else {
        missing.add(reqSkill);
      }
    }

    // Preferred skills give partial bonus
    int preferredHits = 0;
    for (final pSkill in job.preferredSkills) {
      if (_skillMatches(_normalizeOne(pSkill), seekerSkillsNorm)) {
        preferredHits++;
      }
    }

    final skillRatio  = job.skills.isEmpty ? 1.0 : skillHits / job.skills.length;
    final prefBonus   = job.preferredSkills.isEmpty ? 0.0 : preferredHits / job.preferredSkills.length;
    final skillScore  = ((skillRatio * 35) + (prefBonus * 5)).round().clamp(0, 40);

    // ── 2. Experience score (20 pts) ───────────────────────
    int expScore = 0;
    if (seeker.experience >= job.minExp && seeker.experience <= job.maxExp) {
      expScore = 20;
    } else if (seeker.experience > job.maxExp) {
      // Overqualified — partial
      expScore = 12;
    } else {
      // Under-qualified — scale by gap
      final gap = job.minExp - seeker.experience;
      expScore = gap <= 1 ? 15 : gap <= 2 ? 10 : gap <= 3 ? 5 : 0;
    }

    // ── 3. Location score (15 pts) ─────────────────────────
    int locationScore = 0;
    if (job.workMode == 'Remote') {
      locationScore = 15; // Remote = always match
    } else {
      final seekerLoc = seeker.location.toLowerCase();
      final jobLoc    = job.location.toLowerCase();
      if (seekerLoc.contains(jobLoc) || jobLoc.contains(seekerLoc)) {
        locationScore = 15;
      } else if (_sameRegion(seekerLoc, jobLoc)) {
        locationScore = 8;
      } else {
        locationScore = 3; // Willing to relocate assumed
      }
    }

    // ── 4. Contextual / semantic score (25 pts) ───────────
    int contextScore = 0;

    // Title relevance to JD
    final titleRelevance = _titleRelevanceScore(titleNorm, job.title.toLowerCase(), jobDescLower);
    contextScore += (titleRelevance * 10).round();

    // Bio keyword density
    final bioWords = seeker.bio.toLowerCase().split(RegExp(r'\s+'));
    final jdWords  = jobDescLower.split(RegExp(r'\s+')).toSet();
    final bioOverlap = bioWords.where((w) => w.length > 4 && jdWords.contains(w)).length;
    contextScore += (bioOverlap * 2).clamp(0, 8);

    // Implied skills from title
    final implied = _getImpliedSkills(titleNorm);
    final impliedMatches = implied.where((s) => jobDescLower.contains(s)).length;
    contextScore += impliedMatches.clamp(0, 7);

    contextScore = contextScore.clamp(0, 25);

    // ── Total ──────────────────────────────────────────────
    final total = (skillScore + expScore + locationScore + contextScore).clamp(0, 100);

    // ── Strengths & gaps ───────────────────────────────────
    final strengths = _buildStrengths(
      seeker: seeker,
      job: job,
      matchedSkills: matched,
      skillScore: skillScore,
      expScore: expScore,
      locationScore: locationScore,
    );

    final gaps = _buildGaps(
      seeker: seeker,
      job: job,
      missingSkills: missing,
      expScore: expScore,
    );

    // ── Recommendation ─────────────────────────────────────
    final recommendation = _buildRecommendation(
      score: total, matched: matched, missing: missing,
      seeker: seeker, job: job);

    final band = MatchReport.bandFromScore(total);

    return MatchReport(
      score: total,
      band: band,
      bandLabel: MatchReport.labelFromBand(band),
      recommendation: recommendation,
      matchedSkills: matched,
      missingSkills: missing,
      strengths: strengths,
      gaps: gaps,
      skillScore: skillScore,
      experienceScore: expScore,
      locationScore: locationScore,
      contextScore: contextScore,
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  static List<String> _normalizeSkills(List<String> skills) =>
      skills.map(_normalizeOne).toList();

  static String _normalizeOne(String skill) => skill.toLowerCase().trim();

  static bool _skillMatches(String needle, List<String> haystack) {
    if (haystack.contains(needle)) return true;
    // Check alias groups
    for (final entry in _skillAliases.entries) {
      if (entry.value.contains(needle)) {
        // needle is in this alias group — check if any alias is in haystack
        if (entry.value.any((a) => haystack.contains(a))) return true;
      }
    }
    // Partial match (substring)
    if (haystack.any((h) => h.contains(needle) || needle.contains(h))) return true;
    return false;
  }

  static bool _sameRegion(String a, String b) {
    const regions = [
      ['bangalore', 'bengaluru', 'blr'],
      ['hyderabad', 'hyd', 'secunderabad'],
      ['mumbai', 'bombay', 'bom', 'pune', 'navi mumbai'],
      ['delhi', 'ncr', 'gurgaon', 'gurugram', 'noida', 'faridabad'],
      ['chennai', 'madras', 'coimbatore'],
      ['kolkata', 'calcutta'],
    ];
    for (final r in regions) {
      if (r.any((c) => a.contains(c)) && r.any((c) => b.contains(c))) return true;
    }
    return false;
  }

  static double _titleRelevanceScore(
      String seekerTitle, String jobTitle, String jobDesc) {
    double score = 0.0;
    // Direct title word overlap
    final jWords = jobTitle.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final sWords = seekerTitle.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final overlap = jWords.intersection(sWords).length;
    if (jWords.isNotEmpty) score += overlap / jWords.length * 0.7;
    // Title keywords in description
    for (final w in sWords) {
      if (jobDesc.contains(w)) score += 0.05;
    }
    return score.clamp(0.0, 1.0);
  }

  static List<String> _getImpliedSkills(String title) {
    for (final entry in _titleImpliedSkills.entries) {
      if (title.contains(entry.key)) return entry.value;
    }
    return [];
  }

  static List<String> _buildStrengths({
    required AppUser seeker,
    required Job job,
    required List<String> matchedSkills,
    required int skillScore,
    required int expScore,
    required int locationScore,
  }) {
    final s = <String>[];
    if (matchedSkills.length >= 3) {
      s.add('Strong skill overlap: ${matchedSkills.take(3).join(", ")}');
    }
    if (expScore == 20) {
      s.add('Experience perfectly within required range (${seeker.experience} yrs)');
    }
    if (locationScore == 15) {
      s.add(job.workMode == 'Remote' ? 'Role is remote — location no barrier' : 'Located in ${seeker.location}');
    }
    if (seeker.orgVerified) s.add('Organisation email verified — trusted profile');
    if (seeker.profileComplete >= 80) s.add('Complete, well-filled profile');
    if (seeker.skills.length >= job.preferredSkills.length && job.preferredSkills.isNotEmpty) {
      s.add('Covers ${matchedSkills.length} of ${job.skills.length} required skills');
    }
    return s.take(4).toList();
  }

  static List<String> _buildGaps({
    required AppUser seeker,
    required Job job,
    required List<String> missingSkills,
    required int expScore,
  }) {
    final g = <String>[];
    if (missingSkills.isNotEmpty) {
      g.add('Missing ${missingSkills.length} required skill(s): ${missingSkills.take(2).join(", ")}');
    }
    if (expScore < 15) {
      final deficit = job.minExp - seeker.experience;
      if (deficit > 0) g.add('${deficit} year(s) short of minimum experience');
    }
    if (seeker.bio.isEmpty) g.add('No bio — harder for provider to assess fit');
    if (seeker.skills.length < 4) g.add('Few skills listed — may underrepresent capability');
    return g.take(3).toList();
  }

  static String _buildRecommendation({
    required int score,
    required List<String> matched,
    required List<String> missing,
    required AppUser seeker,
    required Job job,
  }) {
    if (score >= 90) {
      return 'Exceptional fit. Candidate matches virtually all requirements. '
          'Highly recommended for direct referral without further review.';
    }
    if (score >= 80) {
      return 'Strong candidate. ${matched.length} of ${job.skills.length} required skills present. '
          'Minimal gaps. Recommend shortlisting for referral.';
    }
    if (score >= 70) {
      return 'Good match overall. A few skills to bridge'
          '${missing.isNotEmpty ? ' (${missing.take(2).join(", ")})' : ''}. '
          'Worth reviewing profile in detail before deciding.';
    }
    if (score >= 60) {
      return 'Borderline match. Candidate shows potential but has notable gaps. '
          'Consider if the team has capacity to ramp up quickly.';
    }
    return 'Low match at this time. Significant skill or experience gaps. '
        'May be worth keeping in pipeline for future openings.';
  }
}
