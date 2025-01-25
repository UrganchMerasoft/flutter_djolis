
import 'package:flutter_djolis/services/utils.dart';

class PayedOrderModel{
  late String id;
  late String name;
  late String curtime;
  late double summ;

  PayedOrderModel({
    required this.id,
    required this.curtime,
    required this.name,
    required this.summ,
  });

  @override
  String toString() {
    return 'PayedOrderModel{id: $id, curtime: $curtime, name: $name, summ: $summ}';
  }

  factory PayedOrderModel.fromJson(Map<String, dynamic> json) {
    return PayedOrderModel(
      id: json["id"] ?? 0,
      curtime: json["curtime"] ?? "",
      name: json["name"] ?? "",
      summ: json["summ"] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() =>{
    "id":id,
    "curtime": curtime,
    "name": name,
    "summ": summ,

  };

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "curtime":curtime,
      "name":name,
      "summ":summ,
    };
  }
  factory PayedOrderModel.fromMapObject(Map<String, dynamic> map) {
    return PayedOrderModel(
      id: map['id'] as String,
      curtime: map['curtime'] as String,
      name: map['name'] as String,
      summ: Utils.checkDouble(map['summ']),
    );
  }
}