class FollowUp {
  const FollowUp({
    required this.id,
    required this.lead,
    required this.type,
    required this.summary,
    this.customerResponse,
    this.nextFollowUpAt,
  });

  final int id;
  final String lead;
  final Object? type;
  final String summary;
  final String? customerResponse;
  final String? nextFollowUpAt;

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'] as int,
      lead: json['lead'] as String? ?? '',
      type: json['type'],
      summary: json['summary'] as String? ?? '',
      customerResponse: json['customerResponse'] as String?,
      nextFollowUpAt: json['nextFollowUpAt'] as String?,
    );
  }
}
