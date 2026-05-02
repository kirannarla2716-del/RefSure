import 'package:mocktail/mocktail.dart';
import 'package:refsure/features/auth/data/auth_repository.dart';
import 'package:refsure/features/profile/data/profile_repository.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/features/applications/data/applications_repository.dart';
import 'package:refsure/features/notifications/data/notifications_repository.dart';
import 'package:refsure/features/messaging/data/messaging_repository.dart';
import 'package:refsure/features/dashboard/data/dashboard_repository.dart';

// Mock repositories
class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockJobsRepository extends Mock implements JobsRepository {}

class MockApplicationsRepository extends Mock
    implements ApplicationsRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockMessagingRepository extends Mock implements MessagingRepository {}

class MockDashboardRepository extends Mock implements DashboardRepository {}
