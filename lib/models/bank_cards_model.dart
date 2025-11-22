class BankCardsModel {
  late int client_id;
  late String name;
  late String cvv;
  late String pan;
  late String expiry;

  BankCardsModel({
    required this.client_id,
    required this.name,
    required this.cvv,
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
      cvv: json["cvv"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "client_id": client_id,
      "name": name,
      "pan": pan,
      "expiry": expiry,
      "cvv": cvv,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "client_id": client_id,
      "name": name,
      "pan": pan,
      "expiry": expiry,
      "cvv": cvv,
    };
  }

  factory BankCardsModel.fromMapObject(Map<String, dynamic> map) {
    return BankCardsModel(
      client_id: map['client_id'] as int,
      name: map['name'] as String,
      pan: map['pan'] as String,
      expiry: map['expiry'] as String,
      cvv: map['cvv'] as String? ?? "",
    );
  }
}
