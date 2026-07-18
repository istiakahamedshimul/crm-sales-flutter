class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.paymentStatus,
    this.leadId,
    this.email,
    this.salesExecutive,
    this.projectId,
    this.project,
    this.projectType,
    this.subGroupId,
    this.subGroup,
  });

  final int id;
  final int? leadId;
  final String name;
  final String phone;
  final String? email;
  final String paymentStatus;
  final String? salesExecutive;
  final int? projectId;
  final String? project;
  final int? projectType;
  final int? subGroupId;
  final String? subGroup;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      leadId: json['leadId'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      paymentStatus: json['paymentStatus'] as String? ?? 'Unpaid',
      salesExecutive: json['salesExecutive'] as String?,
      projectId: json['projectId'] as int?,
      project: json['project'] as String?,
      projectType: json['projectType'] as int?,
      subGroupId: json['subGroupId'] as int?,
      subGroup: json['subGroup'] as String?,
    );
  }
}
