// lib/features/cv_job_matcher/cv_job_matcher.dart — updated barrel

// Models
export 'models/cv_match_result.dart';
export 'models/extracted_profile.dart';
export 'models/job_opening.dart';
export 'models/job_application.dart';

// Services
export 'services/cv_matching_engine.dart';
export 'services/job_fetch_service.dart';

// Data
export 'data/cv_matcher_repository.dart';

// Cubits
export 'presentation/cubit/cv_matcher_cubit.dart';
export 'presentation/cubit/cv_matcher_state.dart';
export 'presentation/cubit/applicants_cubit.dart';

// Screens
export 'presentation/screens/company_jobs_screen.dart';
export 'presentation/screens/apply_with_cv_screen.dart';
export 'presentation/screens/job_applicants_screen.dart';
export 'presentation/screens/applicant_detail_screen.dart';
export 'presentation/screens/match_result_screen.dart';

// Widgets
export 'presentation/widgets/recommendation_badge.dart';
export 'presentation/widgets/score_breakdown_card.dart';
export 'presentation/widgets/skills_section.dart';
export 'presentation/widgets/applicant_card.dart';
