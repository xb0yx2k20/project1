class User {
  String id;
  String name;
  String email;
  String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  // Конвертация в JSON для Firebase
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
      };

  // Конвертация из Firebase
  factory User.fromJson(String id, Map<String, dynamic> json) {
    return User(
      id: id,
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}