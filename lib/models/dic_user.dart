class User {

  late int id;
  late String name;
  late String phone;
  late String contactFio;
  late String address;
  late String gpsLatitude;
  late String gpsLongitude;
  late String password;
  late String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.contactFio,
    required this.address,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.password,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return  User(
      id: json["id"] ?? 0,
      name: json["name"] ?? "?",
      phone: json["phone"] ?? "?",
      contactFio: json["contactFio"] ?? "?",
      address: json["address"] ?? "?",
      gpsLatitude: json["gpsLatitude"] ?? "?",
      gpsLongitude: json["gpsLongitude"] ?? "?",
      password: json["password"] ?? "?",
      avatarUrl: json["avatarUrl"] ?? "?",
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "phone": phone,
        "contactFio": contactFio,
        "address": address,
        "gpsLatitude": gpsLatitude,
        "gpsLongitude": gpsLongitude,
        "password": password,
        "avatarUrl": avatarUrl,
      };

  Map<String,dynamic> toJson(){
    return {
      "id": id,
      "name": name,
      "phone": phone,
      "contactFio": contactFio,
      "address": address,
      "gpsLatitude": gpsLatitude,
      "gpsLongitude": gpsLongitude,
      "password": password,
      "avatarUrl": avatarUrl,
    };
  }

  User.fromMapObject(Map<String, dynamic> map) {
    id = map['id'] ?? "?";
    name = map['name'] ?? "?";
    phone = map['phone'] ?? "?";
    contactFio = map["contactFio"]?? "?";
    address = map["address"]?? "?";
    gpsLatitude = map["gpsLatitude"]?? "?";
    gpsLongitude = map["gpsLongitude"]?? "?";
    password = map['password'] ?? "?";
    avatarUrl = map['avatarUrl'] ?? "?";
  }
}