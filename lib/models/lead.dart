class Lead {
  const Lead({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.status,
    this.email,
    this.assignedToName,
    this.nextFollowUpAt,
    this.projectId,
    this.projectName,
    this.projectType,
    this.source,
    this.referrerName,
    this.referrerPhone,
    this.referrerEmail,
  });

  final int id;
  final String customerName;
  final String phone;
  final String? email;
  final Object? status;
  final String? assignedToName;
  final String? nextFollowUpAt;
  final int? projectId;
  final String? projectName;
  final Object? projectType;
  final Object? source;
  final String? referrerName;
  final String? referrerPhone;
  final String? referrerEmail;

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int,
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      status: json['status'],
      assignedToName: json['assignedToName'] as String?,
      nextFollowUpAt: json['nextFollowUpAt'] as String?,
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String?,
      projectType: json['projectType'],
      source: json['source'],
      referrerName: json['referrerName'] as String?,
      referrerPhone: json['referrerPhone'] as String?,
      referrerEmail: json['referrerEmail'] as String?,
    );
  }
}
