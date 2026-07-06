class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.paymentStatus,
    this.leadId,
    this.email,
    this.salesExecutive,
  });

  final int id;
  final int? leadId;
  final String name;
  final String phone;
  final String? email;
  final String paymentStatus;
  final String? salesExecutive;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      leadId: json['leadId'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      paymentStatus: json['paymentStatus'] as String? ?? 'Unpaid',
      salesExecutive: json['salesExecutive'] as String?,
    );
  }
}
