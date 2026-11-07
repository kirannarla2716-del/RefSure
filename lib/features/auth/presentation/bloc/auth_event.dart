import 'package:equatable/equatable.dart';
import 'package:refsure/core/enums/enums.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class EmailSignInRequested extends AuthEvent {
  const EmailSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class EmailSignUpRequested extends AuthEvent {
  const EmailSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;

  @override
  List<Object?> get props => [name, email, password, role];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested({this.role = UserRole.seeker});

  final UserRole role;

  @override
  List<Object?> get props => [role];
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}
