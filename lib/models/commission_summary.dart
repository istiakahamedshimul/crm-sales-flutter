class CommissionSummary {
  const CommissionSummary({
    required this.totalEarned,
    required this.pending,
    required this.paid,
    required this.history,
  });

  final num totalEarned;
  final num pending;
  final num paid;
  final List<CommissionHistory> history;

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      totalEarned: json['totalEarned'] as num? ?? 0,
      pending: json['pending'] as num? ?? 0,
      paid: json['paid'] as num? ?? 0,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((item) =>
              CommissionHistory.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommissionHistory {
  const CommissionHistory({
    required this.id,
    required this.paymentAmount,
    required this.percentage,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final num paymentAmount;
  final num percentage;
  final num amount;
  final Object? status;
  final String createdAt;

  factory CommissionHistory.fromJson(Map<String, dynamic> json) {
    return CommissionHistory(
      id: json['id'] as int,
      paymentAmount: json['paymentAmount'] as num? ?? 0,
      percentage: json['percentage'] as num? ?? 0,
      amount: json['amount'] as num? ?? 0,
      status: json['status'],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
