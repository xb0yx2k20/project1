class ServiceCenter {
  String id;
  String address; // Адрес сервиса
  List<String> servicesOffered; // Список услуг, которые предоставляет сервис

  ServiceCenter({
    required this.id,
    required this.address,
    required this.servicesOffered,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'servicesOffered': servicesOffered,
      };

  factory ServiceCenter.fromJson(String id, Map<String, dynamic> json) {
    return ServiceCenter(
      id: id,
      address: json['address'],
      servicesOffered: List<String>.from(json['servicesOffered']),
    );
  }
}