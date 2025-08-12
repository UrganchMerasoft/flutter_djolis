class BankCardsModel {
  late int client_id;
  late String name;
  late String pan;
  late String expiry;

  BankCardsModel({
    required this.client_id,
    required this.name,
    required this.pan,
    required this.expiry,
  });


  @override
  String toString() {
    return 'BankCardsModel{client_id: $client_id, name: $name, pan: $pan, expiry: $expiry}';
  }

  factory BankCardsModel.fromJson(Map<String, dynamic> json) {
    return BankCardsModel(
      client_id: json["client_id"] ?? 0,
      name: json["name"] ?? "",
      pan: json["pan"] ?? "",
      expiry: json["expiry"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "client_id": client_id,
      "name": name,
      "pan": pan,
      "expiry": expiry,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "client_id": client_id,
      "name": name,
      "pan": pan,
      "expiry": expiry,
    };
  }

  factory BankCardsModel.fromMapObject(Map<String, dynamic> map) {
    return BankCardsModel(
      client_id: map['client_id'] as int,
      name: map['name'] as String,
      pan: map['pan'] as String,
      expiry: map['expiry'] as String,
    );
  }
}
