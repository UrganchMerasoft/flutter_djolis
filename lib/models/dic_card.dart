import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'my_table.dart';

class DicCardModel extends MyTable {
  late String name;
  late String card_num;
  late String payme_url;
  late String click_url;
  late String uzum_url;

  DicCardModel({
    required this.name,
    required this.card_num,
    required this.payme_url,
    required this.click_url,
    required this.uzum_url,
  });

  factory DicCardModel.fromJson(Map<String, dynamic> json) {
    return DicCardModel(
        name: json['name'],
        card_num: json['card_num'],
        payme_url: json['payme_url'],
        click_url: json['click_url'],
        uzum_url: json['uzum_url'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['name'] = name;
    map['card_num'] = card_num;
    map['payme_url'] = payme_url;
    map['click_url'] = click_url;
    map['uzum_url'] = uzum_url;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "name": name,
      "card_num": card_num,
      "payme_url": payme_url,
      "click_url": click_url,
      "uzum_url": uzum_url,
    };
  }

  @override
  DicCardModel.fromMapObject(Map<String, dynamic> map) {
    name = map['name']??"-";
    card_num = map['card_num']??"-";
    payme_url = map['payme_url']??"-";
    click_url = map['click_url']??"-";
    uzum_url = map['uzum_url']??"-";
  }

  @override
  int getId() {
    return 0;
  }

  DicCardModel.saveFromJsonToDB(Batch bb, String json) {
    List list = jsonDecode(json);
    if (list.isNotEmpty) {
      bb.rawDelete("DELETE FROM dic_cat");
    }

    final List<DicCardModel> localItems = list.map((i) => DicCardModel.fromJson(i)).toList();
    for (var item in localItems) {
      bb.insert("dic_cat", item.toMap());
    }
  }

  DicCardModel.saveFromListMapToDB(Batch bb, List<dynamic>? list) {
    if (list == null) return;
    if (list.isNotEmpty) {
      bb.rawDelete("DELETE FROM dic_cat");
    }

    final List<DicCardModel> localItems = list.map((i) => DicCardModel.fromMapObject(i)).toList();
    for (var item in localItems) {
      bb.insert("dic_cat", item.toMap());
    }
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }

}