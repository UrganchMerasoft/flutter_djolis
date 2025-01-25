
class DicClients{
  late int id;
  late int client_id;
  late String name;
  late String phone;

  DicClients({
    required this.id,
    required this.client_id,
    required this.name,
    required this.phone,
  });

  @override
  String toString() {
    return 'DicClients{id: $id, client_id: $client_id, name: $name, phone: $phone}';
  }

  factory DicClients.fromJson(Map<String, dynamic> json) {
    return DicClients(
      id: json["id"] ?? 0,
      client_id: json["client_id"] ?? 0,
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
    );
  }

  Map<String, dynamic> toMap() =>{
    "id":id,
    "client_id": client_id,
    "name": name,
    "phone": phone,

  };

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "client_id":client_id,
      "name":name,
      "phone":phone,
    };
  }
  factory DicClients.fromMapObject(Map<String, dynamic> map) {
    return DicClients(
      id: map['id'] as int,
      client_id: map['client_id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }
}