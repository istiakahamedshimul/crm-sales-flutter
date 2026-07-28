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
    );
  }
}
