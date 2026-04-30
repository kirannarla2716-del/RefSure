import 'package:equatable/equatable.dart';
import 'package:refsure/core/models/application.dart';

sealed class ApplicationsState extends Equatable {
  const ApplicationsState();

  @override
  List<Object?> get props => [];
}

class ApplicationsInitial extends ApplicationsState {
  const ApplicationsInitial();
}

class ApplicationsLoading extends ApplicationsState {
  const ApplicationsLoading();
}

class ApplicationsLoaded extends ApplicationsState {
  const ApplicationsLoaded({required this.applications});

  final List<Application> applications;

  @override
  List<Object?> get props => [applications];
}

class ApplicationSubmitting extends ApplicationsState {
  const ApplicationSubmitting();
}

class ApplicationSubmitted extends ApplicationsState {
  const ApplicationSubmitted();
}

class ApplicationsError extends ApplicationsState {
  const ApplicationsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
