import '../enums/enums.dart';

abstract final class RoleLabels {
  static String name(UserRole role) => switch (role) {
        UserRole.seeker => 'Referral-SEEKER',
        UserRole.provider => 'Referral-PROVIDER',
      };

  static String mode(UserRole role) => '${name(role)} Mode';
}
