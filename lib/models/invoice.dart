class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.finalAmount,
    required this.status,
    required this.dueDate,
    required this.salesExecutive,
  });

  final int id;
  final String invoiceNumber;
  final String customer;
  final String salesExecutive;
  final num finalAmount;
  final Object? status;
  final String dueDate;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customer: json['customer'] as String? ?? '',
      salesExecutive: json['salesExecutive'] as String? ?? '',
      finalAmount: json['finalAmount'] as num? ?? 0,
      status: json['status'],
      dueDate: json['dueDate'] as String? ?? '',
    );
  }
}
