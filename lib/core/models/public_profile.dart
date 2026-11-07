import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/app_user.dart';

/// Non-sensitive profile projection used for authenticated discovery.
///
/// Email addresses, resume URLs, compensation, availability, education, and
/// private onboarding fields intentionally do not belong in this model.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.headline,
    required this.title,
    required this.location,
    required this.experience,
    required this.skills,
    required this.preferredRoles,
    required this.bio,
    required this.verified,
    required this.orgVerified,
    required this.profileComplete,
    required this.referralsReceived,
    required this.referralsMade,
    required this.successfulReferrals,
    required this.totalJobsPosted,
    required this.successRate,
    required this.responseTime,
    required this.avgResponseHours,
    required this.responseRate,
    required this.trustScore,
    required this.gratitudesReceived,
    required this.availableForReferrals,
    required this.weeklyReferralCapacity,
    required this.createdAt,
    required this.updatedAt,
    this.company,
    this.photoUrl,
  });

  final String id;
  final UserRole role;
  final String name;
  final String headline;
  final String title;
  final String location;
  final int experience;
  final List<String> skills;
  final List<String> preferredRoles;
  final String bio;
  final String? company;
  final String? photoUrl;
  final bool verified;
  final bool orgVerified;
  final int profileComplete;
  final int referralsReceived;
  final int referralsMade;
  final int successfulReferrals;
  final int totalJobsPosted;
  final int successRate;
  final String responseTime;
  final int avgResponseHours;
  final double responseRate;
  final double trustScore;
  final int gratitudesReceived;
  final bool availableForReferrals;
  final int weeklyReferralCapacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'role': role.name,
        'name': name,
        'headline': headline,
        'title': title,
        'location': location,
        'experience': experience,
        'skills': skills,
        'preferredRoles': preferredRoles,
        'bio': bio,
        'company': company,
        'photoUrl': photoUrl,
        'verified': verified,
        'orgVerified': orgVerified,
        'profileComplete': profileComplete,
        'referralsReceived': referralsReceived,
        'referralsMade': referralsMade,
        'successfulReferrals': successfulReferrals,
        'totalJobsPosted': totalJobsPosted,
        'successRate': successRate,
        'responseTime': responseTime,
        'avgResponseHours': avgResponseHours,
        'responseRate': responseRate,
        'trustScore': trustScore,
        'gratitudesReceived': gratitudesReceived,
        'availableForReferrals': availableForReferrals,
        'weeklyReferralCapacity': weeklyReferralCapacity,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      };

  factory PublicProfile.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return PublicProfile(
      id: snapshot.id,
      role: data['role'] == 'provider' ? UserRole.provider : UserRole.seeker,
      name: data['name'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      title: data['title'] as String? ?? '',
      location: data['location'] as String? ?? '',
      experience: (data['experience'] as num? ?? 0).round(),
      skills: List<String>.from(data['skills'] as List? ?? const []),
      preferredRoles:
          List<String>.from(data['preferredRoles'] as List? ?? const []),
      bio: data['bio'] as String? ?? '',
      company: data['company'] as String?,
      photoUrl: data['photoUrl'] as String?,
      verified: data['verified'] as bool? ?? false,
      orgVerified: data['orgVerified'] as bool? ?? false,
      profileComplete: (data['profileComplete'] as num? ?? 0).round(),
      referralsReceived: (data['referralsReceived'] as num? ?? 0).round(),
      referralsMade: (data['referralsMade'] as num? ?? 0).round(),
      successfulReferrals: (data['successfulReferrals'] as num? ?? 0).round(),
      totalJobsPosted: (data['totalJobsPosted'] as num? ?? 0).round(),
      successRate: (data['successRate'] as num? ?? 0).round(),
      responseTime: data['responseTime'] as String? ?? '',
      avgResponseHours: (data['avgResponseHours'] as num? ?? 48).round(),
      responseRate: (data['responseRate'] as num? ?? 0).toDouble(),
      trustScore: (data['trustScore'] as num? ?? 0).toDouble(),
      gratitudesReceived: (data['gratitudesReceived'] as num? ?? 0).round(),
      availableForReferrals: data['availableForReferrals'] as bool? ?? true,
      weeklyReferralCapacity:
          (data['weeklyReferralCapacity'] as num? ?? 5).round(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Compatibility adapter for existing discovery consumers.
  ///
  /// Private fields remain null because they are never projected.
  AppUser toAppUser() => AppUser(
        id: id,
        role: role,
        name: name,
        headline: headline,
        company: company,
        verified: verified,
        orgVerified: orgVerified,
        title: title,
        location: location,
        experience: experience,
        skills: skills,
        preferredRoles: preferredRoles,
        bio: bio,
        photoUrl: photoUrl,
        createdAt: createdAt,
        lastActiveAt: updatedAt,
        profileComplete: profileComplete,
        referralsReceived: referralsReceived,
        referralsMade: referralsMade,
        successfulReferrals: successfulReferrals,
        totalJobsPosted: totalJobsPosted,
        successRate: successRate,
        responseTime: responseTime,
        avgResponseHours: avgResponseHours,
        responseRate: responseRate,
        trustScore: trustScore,
        gratitudesReceived: gratitudesReceived,
        availableForReferrals: availableForReferrals,
        weeklyReferralCapacity: weeklyReferralCapacity,
      );
}
