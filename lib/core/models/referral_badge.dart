// ignore_for_file: sort_constructors_first

import 'package:refsure/core/enums/enums.dart';

class ReferralBadge {
  final ReferralBadgeTier tier;
  final String label;
  const ReferralBadge(this.tier, this.label);

  static ReferralBadge? fromCount(int n) {
    if (n >= 300) return const ReferralBadge(ReferralBadgeTier.platinum, 'Platinum');
    if (n >= 100) return const ReferralBadge(ReferralBadgeTier.diamond,  'Diamond');
    if (n >= 30)  return const ReferralBadge(ReferralBadgeTier.gold,     'Gold');
    if (n >= 10)  return const ReferralBadge(ReferralBadgeTier.silver,   'Silver');
    if (n >= 1)   return const ReferralBadge(ReferralBadgeTier.bronze,   'Bronze');
    return null;
  }
}
