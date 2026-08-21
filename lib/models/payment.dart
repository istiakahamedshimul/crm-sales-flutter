class Payment {
  const Payment({
    required this.id,
    required this.customer,
    required this.collectionNumber,
    required this.amount,
    required this.status,
    this.salesExecutive,
    this.proofUrl,
    this.rejectReason,
    this.paymentDate,
    this.method,
    this.purpose,
    this.transactionReference,
    this.remarks,
    this.isReversed = false,
    this.reversalReason,
  });

  final int id;
  final String customer;
  final String collectionNumber;
  final String? salesExecutive;
  final num amount;
  final Object? status;
  final String? proofUrl;
  final String? rejectReason;
  final DateTime? paymentDate;
  final Object? method;
  final Object? purpose;
  final String? transactionReference;
  final String? remarks;
  final bool isReversed;
  final String? reversalReason;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      customer: json['customer'] as String? ?? '',
      collectionNumber: json['collectionNumber'] as String? ?? '',
      salesExecutive: json['salesExecutive'] as String?,
      amount: json['amount'] as num? ?? 0,
      status: json['status'],
      proofUrl: json['proofUrl'] as String?,
      rejectReason: json['rejectReason'] as String?,
      paymentDate: json['paymentDate'] == null ? null : DateTime.parse(json['paymentDate'] as String),
      method: json['method'],
      purpose: json['purpose'],
      transactionReference: json['transactionReference'] as String?,
      remarks: json['remarks'] as String?,
      isReversed: json['isReversed'] as bool? ?? false,
      reversalReason: json['reversalReason'] as String?,
    );
  }
}
