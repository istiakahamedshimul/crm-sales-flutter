class MonthlyCollection {
  const MonthlyCollection({required this.id, required this.month, required this.amount, this.remarks});
  final int id;
  final DateTime month;
  final double amount;
  final String? remarks;
  factory MonthlyCollection.fromJson(Map<String,dynamic> json) => MonthlyCollection(
    id: json['id'] as int,
    month: DateTime.parse(json['month'] as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    remarks: json['remarks'] as String?,
  );
}
