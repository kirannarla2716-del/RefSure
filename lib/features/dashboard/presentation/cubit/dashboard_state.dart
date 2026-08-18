import 'package:equatable/equatable.dart';
import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/core/models/application.dart';
import 'package:refsure/core/models/job.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.seekers,
    required this.jobs,
    required this.applications,
  });

  final List<AppUser> seekers;
  final List<Job> jobs;
  final List<Application> applications;

  @override
  List<Object?> get props => [seekers, jobs, applications];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
