class Payment {
  const Payment({
    required this.id,
    required this.customer,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    this.salesExecutive,
    this.proofUrl,
    this.rejectReason,
  });

  final int id;
  final String customer;
  final String invoiceNumber;
  final String? salesExecutive;
  final num amount;
  final Object? status;
  final String? proofUrl;
  final String? rejectReason;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      customer: json['customer'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      salesExecutive: json['salesExecutive'] as String?,
      amount: json['amount'] as num? ?? 0,
      status: json['status'],
      proofUrl: json['proofUrl'] as String?,
      rejectReason: json['rejectReason'] as String?,
    );
  }
}
