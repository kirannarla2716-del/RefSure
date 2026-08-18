// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RefSure';

  @override
  String get appTagline => 'Where real referrals happen.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendLink => 'Send Link';

  @override
  String get cancel => 'Cancel';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get passwordHint => 'Password (6+ chars)';

  @override
  String get jobSeeker => 'Job Seeker';

  @override
  String get provider => 'Provider';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get home => 'Home';

  @override
  String get jobs => 'Jobs';

  @override
  String get providers => 'Providers';

  @override
  String get applied => 'Applied';

  @override
  String get profile => 'Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get seekers => 'Seekers';

  @override
  String get messages => 'Messages';

  @override
  String get myApplications => 'My Applications';

  @override
  String get notifications => 'Notifications';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get postJob => 'Post a Job';

  @override
  String get verifyOrganization => 'Verify Organization';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get company => 'Company';

  @override
  String get location => 'Location';

  @override
  String get bioSummary => 'Bio / Summary';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get apply => 'Apply';

  @override
  String get appliedLabel => 'Applied';

  @override
  String get applicationApplied =>
      'Applied! Provider will review your profile.';

  @override
  String get alreadyApplied => 'Already applied to this job.';

  @override
  String get matchScoreTooLow =>
      'Match score too low (< 40%). Update your profile to qualify.';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String get noApplicationsYet => 'No applications yet';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noMessages => 'No messages yet';

  @override
  String nApplied(int count) {
    return '$count applied';
  }

  @override
  String nYearsExperience(int min, int max) {
    return '$min–$max yrs';
  }

  @override
  String get trustScore => 'Trust Score';

  @override
  String get profileStrength => 'Profile Strength';

  @override
  String get highTrust => 'High Trust';

  @override
  String get buildingTrust => 'Building Trust';

  @override
  String get newUser => 'New';

  @override
  String get verified => 'Verified';

  @override
  String get orgVerified => 'Org Verified';

  @override
  String get hot => 'HOT';

  @override
  String get newLabel => 'NEW';

  @override
  String get all => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get referred => 'Referred';

  @override
  String get interview => 'Interview';

  @override
  String get hired => 'Hired';

  @override
  String get shortlisted => 'Shortlisted';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get closed => 'Closed';

  @override
  String get underReview => 'Under Review';

  @override
  String get strongMatch => 'Strong Match';

  @override
  String get needsReview => 'Needs Review';

  @override
  String get remote => 'Remote';

  @override
  String get hybrid => 'Hybrid';

  @override
  String get onSite => 'On-site';

  @override
  String get referrals => 'Referrals';

  @override
  String get success => 'Success';

  @override
  String get response => 'Response';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileMissing => 'Your account exists but profile is missing.';

  @override
  String get signOutAndSignUp => 'Sign Out & Sign Up Again';

  @override
  String get completeProfileSetup => 'Complete Profile Setup';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';
}
