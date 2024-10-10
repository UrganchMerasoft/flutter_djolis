import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'my_table.dart';

class DicCatModel extends MyTable {
  late String name;
  late List groups;

  DicCatModel({
    required this.name,
    required this.groups,
  });

  factory DicCatModel.fromJson(Map<String, dynamic> json) {
    return DicCatModel(
        name: json['name'],
        groups: json['groups'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['name'] = name;
    map['groups'] = groups;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "name": name,
      "groups": groups,
    };
  }

  @override
  DicCatModel.fromMapObject(Map<String, dynamic> map) {
    name = map['name']??"-";
    groups = map['groups']??"-";
  }

  @override
  int getId() {
    return 0;
  }

  DicCatModel.saveFromJsonToDB(Batch bb, String json) {
    List list = jsonDecode(json);
    if (list.isNotEmpty) {
      bb.rawDelete("DELETE FROM dic_cat");
    }

    final List<DicCatModel> localItems = list.map((i) => DicCatModel.fromJson(i)).toList();
    for (var item in localItems) {
      bb.insert("dic_cat", item.toMap());
    }
  }

  DicCatModel.saveFromListMapToDB(Batch bb, List<dynamic>? list) {
    if (list == null) return;
    if (list.isNotEmpty) {
      bb.rawDelete("DELETE FROM dic_cat");
    }

    final List<DicCatModel> localItems = list.map((i) => DicCatModel.fromMapObject(i)).toList();
    for (var item in localItems) {
      bb.insert("dic_cat", item.toMap());
    }
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }

}