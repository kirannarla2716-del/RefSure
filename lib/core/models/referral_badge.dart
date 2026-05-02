// ignore_for_file: sort_constructors_first

import 'package:refsure/core/enums/enums.dart';

class ReferralBadge {
  final ReferralBadgeTier tier;
  final String label, emoji;
  const ReferralBadge(this.tier, this.label, this.emoji);

  static ReferralBadge? fromCount(int n) {
    if (n >= 300) return const ReferralBadge(ReferralBadgeTier.platinum, 'Platinum', '\u{1F3C6}');
    if (n >= 100) return const ReferralBadge(ReferralBadgeTier.diamond,  'Diamond',  '\u{1F48E}');
    if (n >= 30)  return const ReferralBadge(ReferralBadgeTier.gold,     'Gold',     '\u{1F947}');
    if (n >= 10)  return const ReferralBadge(ReferralBadgeTier.silver,   'Silver',   '\u{1F948}');
    if (n >= 1)   return const ReferralBadge(ReferralBadgeTier.bronze,   'Bronze',   '\u{1F949}');
    return null;
  }
}
