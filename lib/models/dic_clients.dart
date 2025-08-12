
class DicClients{
  late int id;
  late int client_id;
  late String name;
  late String phone;
  late String psw;

  DicClients({
    required this.id,
    required this.client_id,
    required this.name,
    required this.phone,
    required this.psw,
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
      psw: json["psw"],
    );
  }

  Map<String, dynamic> toMap() =>{
    "id":id,
    "client_id": client_id,
    "name": name,
    "phone": phone,
    "psw": psw,

  };

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "client_id":client_id,
      "name":name,
      "phone":phone,
      "psw":psw,
    };
  }
  factory DicClients.fromMapObject(Map<String, dynamic> map) {
    return DicClients(
      id: map['id'] as int,
      client_id: map['client_id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      psw: map['psw'] as String,
    );
  }
}