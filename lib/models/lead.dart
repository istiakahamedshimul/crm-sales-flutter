class Lead {
  const Lead({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.status,
    required this.priority,
    this.email,
    this.assignedToName,
    this.nextFollowUpAt,
  });

  final int id;
  final String customerName;
  final String phone;
  final String? email;
  final Object? status;
  final Object? priority;
  final String? assignedToName;
  final String? nextFollowUpAt;

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int,
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      status: json['status'],
      priority: json['priority'],
      assignedToName: json['assignedToName'] as String?,
      nextFollowUpAt: json['nextFollowUpAt'] as String?,
    );
  }
}
