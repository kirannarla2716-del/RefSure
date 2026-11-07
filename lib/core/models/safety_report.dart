class SafetyReport {
  const SafetyReport({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.category,
    required this.details,
    required this.status,
    required this.createdAt,
    this.contextId,
  });

  final String id;
  final String reporterId;
  final String targetId;
  final String category;
  final String details;
  final String status;
  final DateTime createdAt;
  final String? contextId;

  factory SafetyReport.fromJson(Map<String, dynamic> json) => SafetyReport(
        id: json['id']?.toString() ?? '',
        reporterId: json['reporterId']?.toString() ?? '',
        targetId: json['targetId']?.toString() ?? '',
        category: json['category']?.toString() ?? 'other',
        details: json['details']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        contextId: json['contextId']?.toString(),
      );
}
