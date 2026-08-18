class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.disabled,
    required this.additionalAccess,
    this.onboardingExceptionUntil,
    this.onboardingExceptionReason,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool disabled;
  final List<String> additionalAccess;
  final DateTime? onboardingExceptionUntil;
  final String? onboardingExceptionReason;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'seeker',
        disabled: json['disabled'] == true,
        additionalAccess: switch (json['additionalAccess']) {
          final Iterable<dynamic> values => List<String>.from(values),
          _ => const <String>[],
        },
        onboardingExceptionUntil: DateTime.tryParse(
            json['onboardingExceptionUntil']?.toString() ?? ''),
        onboardingExceptionReason:
            json['onboardingExceptionReason']?.toString(),
      );
}
