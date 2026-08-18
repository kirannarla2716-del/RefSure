enum FeatureCheck {
  userNeed,
  importance,
  usability,
  valueAdd,
  acceptanceEvidence,
}

extension FeatureCheckLabel on FeatureCheck {
  String get label => switch (this) {
        FeatureCheck.userNeed => 'A real user needs this feature',
        FeatureCheck.importance => 'The problem is important enough to solve',
        FeatureCheck.usability => 'Users can discover and use it successfully',
        FeatureCheck.valueAdd => 'The user and RefSure value is measurable',
        FeatureCheck.acceptanceEvidence => 'BDD acceptance scenarios pass',
      };
}

class FeatureReadiness {
  const FeatureReadiness({required this.featureName, this.passed = const {}});

  final String featureName;
  final Set<FeatureCheck> passed;

  bool get isAvailable => FeatureCheck.values.every(passed.contains);

  FeatureReadiness setCheck(FeatureCheck check, bool value) {
    final next = {...passed};
    value ? next.add(check) : next.remove(check);
    return FeatureReadiness(featureName: featureName, passed: next);
  }
}
