import '../enums/enums.dart';

abstract final class ApplicationTransitionPolicy {
  static const Map<AppStatus, Set<AppStatus>> _transitions = {
    AppStatus.pending: {
      AppStatus.accepted,
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
      AppStatus.underReview,
      AppStatus.strongMatch,
      AppStatus.needsReview,
      AppStatus.shortlisted,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.accepted: {
      AppStatus.underReview,
      AppStatus.shortlisted,
      AppStatus.referred,
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
    },
    AppStatus.declined: {},
    AppStatus.withdrawn: {},
    AppStatus.expired: {},
    AppStatus.underReview: {
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
      AppStatus.strongMatch,
      AppStatus.needsReview,
      AppStatus.shortlisted,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.strongMatch: {
      AppStatus.accepted,
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
      AppStatus.shortlisted,
      AppStatus.referred,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.needsReview: {
      AppStatus.accepted,
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
      AppStatus.underReview,
      AppStatus.strongMatch,
      AppStatus.shortlisted,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.shortlisted: {
      AppStatus.declined,
      AppStatus.withdrawn,
      AppStatus.expired,
      AppStatus.referred,
      AppStatus.interview,
      AppStatus.hired,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.referred: {
      AppStatus.interview,
      AppStatus.hired,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.interview: {
      AppStatus.hired,
      AppStatus.notSelected,
      AppStatus.closed,
    },
    AppStatus.hired: {},
    AppStatus.notSelected: {},
    AppStatus.closed: {},
  };

  static bool allows(AppStatus from, AppStatus to) =>
      _transitions[from]?.contains(to) ?? false;
}
