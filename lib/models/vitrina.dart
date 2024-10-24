import 'dart:convert';
import 'package:flutter_djolis/models/dic_prod.dart';

import 'my_table.dart';

class VitrinaModel extends MyTable {
  late int prodId;
  DicProd? prod;
  late double prevOst;
  late double ost;
  late double qty;
  late double price;
  late double summ;

  VitrinaModel({
    required this.prodId,
    required this.prevOst,
    required this.ost,
    required this.qty,
    required this.price,
    required this.summ,
  });

  factory VitrinaModel.fromJson(Map<String, dynamic> json) {
    return VitrinaModel(
      prodId: json['prodId'],
      prevOst: json['prevOst'],
      ost: json['ost'],
      qty: json['qty'],
      price: json['price'],
      summ: json['summ'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['prodId'] = prodId;
    map['prevOst'] = prevOst;
    map['ost'] = ost;
    map['qty'] = qty;
    map['price'] = price;
    map['summ'] = summ;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "prodId": prodId,
      "prevOst": prevOst,
      "ost": ost,
      "qty": qty,
      "price": price,
      "summ": summ,
    };
  }

  @override
  VitrinaModel.fromMapObject(Map<String, dynamic> map) {
    prodId = map['prodId']??0;
    prevOst = map['prevOst']??0.0;
    ost = map['ost']??0.0;
    qty = map['qty']??0.0;
    price = map['price']??0.0;
    summ = map['summ']??0.0;
  }

  @override
  int getId() {
    return 0;
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }

  static List<VitrinaModel> fromJsonList(List<dynamic> list) {
    if (list.isEmpty) return [];

    List<VitrinaModel> carts = [];
    for (var l in list) {
      carts.add(VitrinaModel.fromJson(l));
    }
    return carts;
  }

}