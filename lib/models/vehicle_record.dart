class Vehicle {
  String id;
  String userId; // Пользователь, которому принадлежит машина
  String make; // Марка машины
  String model; // Модель машины
  int year; // Год выпуска
  String vin; // VIN номер машины

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
  });

  // Конвертация в JSON для Firebase
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'make': make,
        'model': model,
        'year': year,
        'vin': vin,
      };

  // Конвертация из Firebase
  factory Vehicle.fromJson(String id, Map<String, dynamic> json) {
    return Vehicle(
      id: id,
      userId: json['userId'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vin: json['vin'],
    );
  }
}