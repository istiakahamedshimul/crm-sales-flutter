class VehicleBooking {
  const VehicleBooking({required this.id, required this.visitDate, required this.visitTime,
    required this.personCount, required this.customer, required this.project, required this.pickupPlace,
    required this.purpose, required this.status, this.vehicle, this.driver, this.adminRemarks});
  final int id, personCount, status;
  final DateTime visitDate;
  final String visitTime, customer, project, pickupPlace, purpose;
  final String? vehicle, driver, adminRemarks;
  factory VehicleBooking.fromJson(Map<String,dynamic> json)=>VehicleBooking(
    id:json['id'] as int, visitDate:DateTime.parse(json['visitDate'] as String),
    visitTime:json['visitTime'] as String? ?? '', personCount:json['personCount'] as int,
    customer:json['customer'] as String? ?? '', project:json['project'] as String? ?? '',
    pickupPlace:json['pickupPlace'] as String? ?? '', purpose:json['purpose'] as String? ?? 'Site Visit',
    status:json['status'] as int, vehicle:json['vehicle'] as String?, driver:json['driver'] as String?, adminRemarks:json['adminRemarks'] as String?);
}
