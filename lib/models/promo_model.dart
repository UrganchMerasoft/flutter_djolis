import '../services/utils.dart';

class PromoModel {

  late int id;
  late int client_id;
  late String client_name;
  late int product_id;
  late String product_name;
  late String date_from;
  late String date_to;
  late int base_id;
  late String base_name;
  late String msg;
  late double val1;
  late double fact_qty;

  PromoModel({
    required this.id,
    required client_id,
    required client_name,
    required product_id,
    required product_name,
    required date_from,
    required date_to,
    required base_id,
    required base_name,
    required msg,
    required val1,
    required fact_qty,
  });


  @override
  String toString() {
    return 'PromoModel{id: $id, client_id: $client_id, client_name: $client_name, product_id: $product_id, product_name: $product_name, date_from: $date_from, date_to: $date_to, base_id: $base_id, base_name: $base_name, msg: $msg, val1: $val1, fact_qty: $fact_qty}';
  }

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
        id: json['id'] ?? 0,
        client_id: json['client_id'] ?? 0,
        client_name: json['client_name'] ?? '',
        product_id: json['product_id'] ?? 0,
        product_name: json['product_name'] ?? '',
        date_from: json['date_from'] ?? '',
        date_to: json['date_to'] ?? '',
        base_id: json['base_id'] ?? 0,
        base_name: json['base_name'] ?? '',
        msg: json['msg'] ?? '',
        val1: json['val1'] ?? 0,
        fact_qty: json['fact_qty'] ?? 0);
  }

  Map<String, dynamic> toMap()=>{
    'id':id,
    'client_id':client_id,
    'client_name':client_name,
    'product_id':product_id,
    'product_name':product_name,
    'date_from':date_from,
    'date_to':date_to,
    'base_id':base_id,
    'base_name':base_name,
    'msg':msg,
    'val1':val1,
    'fact_qty':fact_qty,
  };

  Map<String,dynamic> toJson(){
    return {
      'id':id,
      'client_id':client_id,
      'client_name':client_name,
      'product_id':product_id,
      'product_name':product_name,
      'date_from':date_from,
      'date_to':date_to,
      'base_id':base_id,
      'base_name':base_name,
      'msg':msg,
      'val1':val1,
      'fact_qty':fact_qty,
    };
  }

  PromoModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'] ?? 0;
    client_id = map['client_id'] ?? 0;
    client_name = map['client_name'] ?? '';
    product_id = map['product_id'] ?? 0;
    product_name = map['product_name'] ?? '';
    date_from = map['date_from'] ?? '';
    date_to = map['date_to'] ?? '';
    base_id = map['base_id'] ?? 0;
    base_name = map['base_name'] ?? '';
    msg = map['msg'] ?? '';
    val1 = Utils.checkDouble(map['val1']);
    fact_qty = Utils.checkDouble(map['fact_qty']);
  }
}