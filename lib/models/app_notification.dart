class AppNotification {
  const AppNotification({required this.id, required this.title, required this.message, required this.type, required this.isRead, required this.createdAt, this.screen, this.leadId, this.customerId});
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? screen;
  final int? leadId;
  final int? customerId;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as int, title: json['title'] as String? ?? '', message: json['message'] as String? ?? '',
    type: json['type'] as String? ?? 'General', isRead: json['isRead'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String), screen: json['screen'] as String?,
    leadId: json['leadId'] as int?, customerId: json['customerId'] as int?,
  );
}
