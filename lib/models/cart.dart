import 'dart:convert';
import 'package:flutter_djolis/models/dic_prod.dart';

import 'my_table.dart';

class CartModel extends MyTable {
  late int prodId;
  DicProd? prod;
  late double qty;
  late double price;
  late double summ;

  CartModel({
    required this.prodId,
    required this.qty,
    required this.price,
    required this.summ,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      prodId: json['prodId'],
      qty: json['qty'],
      price: json['price'],
      summ: json['summ'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['prodId'] = prodId;
    map['qty'] = qty;
    map['price'] = price;
    map['summ'] = summ;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "prodId": prodId,
      "qty": qty,
      "price": price,
      "summ": summ,
    };
  }

  @override
  CartModel.fromMapObject(Map<String, dynamic> map) {
    prodId = map['prodId']??0;
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

  static List<CartModel> fromJsonList(List<dynamic> list) {
    if (list.isEmpty) return [];

    List<CartModel> carts = [];
    for (var l in list) {
      carts.add(CartModel.fromJson(l));
    }
    return carts;
  }

}