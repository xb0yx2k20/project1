class MaintenanceRecord {
  String id;
  String type; // "Замена масла", "Замена тормозов"
  int mileage; // Пробег на момент замены
  DateTime date;

  MaintenanceRecord({
    required this.id,
    required this.type,
    required this.mileage,
    required this.date,
  });

  // Конвертация в JSON для Firebase
  Map<String, dynamic> toJson() => {
        'type': type,
        'mileage': mileage,
        'date': date.toIso8601String(),
      };

  // Конвертация из Firebase
  factory MaintenanceRecord.fromJson(String id, Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: id,
      type: json['type'],
      mileage: json['mileage'],
      date: DateTime.parse(json['date']),
    );
  }
}
