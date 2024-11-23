import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'my_table.dart';

 var json = {
"id": 141971,
"doc_type": "order",
"curdate_str": "30.04.2024",
"curtime_str": "03:39:40",
"notes": "ertaga oborib berila",
"summ": 20
};

class MalumotModel extends MyTable {
  late int id;
  late String doc_type;
  late String curdate_str;
  late String curtime_str;
  late String notes;
  late int summ;

  MalumotModel({
    required this.id,
    required this.doc_type,
    required this.curdate_str,
    required this.curtime_str,
    required this.notes,
    required this.summ,
  });

  factory MalumotModel.fromJson(Map<String, dynamic> json) {
    return MalumotModel(
      id: json['id'],
      doc_type: json['doc_type'],
      curdate_str: json['curdate_str'],
      curtime_str: json['curtime_str'],
      notes: json['notes'],
      summ: json['summ'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['id'] = id;
    map['doc_type'] = doc_type;
    map['curdate_str'] = curdate_str;
    map['curtime_str'] = curtime_str;
    map['notes'] = notes;
    map['summ'] = summ;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "id": id,
      "doc_type": doc_type,
      "curdate_str": curdate_str,
      "curtime_str": curtime_str,
      "notes": notes,
    };
  }

  @override
  MalumotModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id']??0;
    doc_type = map['doc_type']??"";
    curdate_str = map['curdate_str']??"";
    curtime_str = map['curtime_str']??"";
    notes = map['notes']??"";
    summ = map['summ']?? 0;
  }

  @override
  int getId() {
    return 0;
  }

  MalumotModel.saveFromJsonToDB(Batch bb, String json) {
    List list = jsonDecode(json);
    if (list.isNotEmpty) {
      bb.rawDelete("DELETE FROM dic_cat");
    }
  }
  //
  //   final List<NotifModel> localItems = list.map((i) => NotifModel.fromJson(i)).toList();
  //   for (var item in localItems) {
  //     bb.insert("dic_cat", item.toMap());
  //   }
  // }
  //
  // NotifModel.saveFromListMapToDB(Batch bb, List<dynamic>? list) {
  //   if (list == null) return;
  //   if (list.isNotEmpty) {
  //     bb.rawDelete("DELETE FROM dic_cat");
  //   }
  //
  //   final List<NotifModel> localItems = list.map((i) => NotifModel.fromMapObject(i)).toList();
  //   for (var item in localItems) {
  //     bb.insert("dic_cat", item.toMap());
  //   }
  // }

  @override
  String getTableName() {
    throw UnimplementedError();
  }

}