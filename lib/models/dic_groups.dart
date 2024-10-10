import 'package:flutter_djolis/services/utils.dart';

class DicGroups {
  late int id;
  late String catName;
  late String name;
  late String picUrl;
  late int prodCount;
  late double orderSumm;

  DicGroups({
    required this.id,
    required this.catName,
    required this.name,
    required this.picUrl,
    required this.prodCount,
    required this.orderSumm
  });


  @override
  String toString() {
    return 'DicGroups{id: $id, catName: $catName, name: $name, picUrl: $picUrl, prodCount: $prodCount, orderSumm: $orderSumm}';
  }

  factory DicGroups.fromJson(Map<String, dynamic> json) {
    return DicGroups(
      id: json["id"] ?? 0,
      catName: json["catName"] ?? "?",
      name: json["name"] ?? "?",
      picUrl: json["picUrl"] ?? "?",
      prodCount: json["prod_count"] ?? 0,
      orderSumm: json["orderSumm"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() =>{
    "id":id,
    "catName": catName,
    "name": name,
    "picUrl": picUrl,
    "prod_count" : prodCount,
    "orderSumm" : orderSumm,
  };

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "catName": catName,
      "name": name,
      "picUrl": picUrl,
      "prod_count" : prodCount,
      "orderSumm" : orderSumm,
    };
  }

  DicGroups.fromMapObject(Map<String, dynamic> map){
    id = map['id'] ?? 0;
    catName = map["catName"] ?? "?";
    name = map["name"] ?? "?";
    picUrl = map["picUrl"] ?? "?";
    prodCount = Utils.checkDouble(map["prod_count"]).toInt();
    orderSumm = Utils.checkDouble(map["orderSumm"]);
  }
}
