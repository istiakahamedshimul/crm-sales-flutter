class VehicleBooking {
  const VehicleBooking({
    required this.id,
    required this.visitDate,
    required this.personCount,
    required this.visitPlace,
    required this.pickupPlace,
    required this.status,
    this.adminRemarks,
  });

  final int id;
  final DateTime visitDate;
  final int personCount;
  final String visitPlace;
  final String pickupPlace;
  final int status;
  final String? adminRemarks;

  factory VehicleBooking.fromJson(Map<String, dynamic> json) => VehicleBooking(
        id: json['id'] as int,
        visitDate: DateTime.parse(json['visitDate'] as String),
        personCount: json['personCount'] as int,
        visitPlace: json['visitPlace'] as String? ?? '',
        pickupPlace: json['pickupPlace'] as String? ?? '',
        status: json['status'] as int,
        adminRemarks: json['adminRemarks'] as String?,
      );
}
