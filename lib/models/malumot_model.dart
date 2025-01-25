import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:sqflite/sqflite.dart';

import 'my_table.dart';


class MalumotModel extends MyTable {
  late int id;
  late String doc_type;
  late String curdate_str;
  late String curtime_str;
  late String notes;
  late double summ;
  late double summ_uzs;
  late String cur_name;

  MalumotModel({
    required this.id,
    required this.doc_type,
    required this.curdate_str,
    required this.curtime_str,
    required this.notes,
    required this.summ,
    required this.summ_uzs,
    required this.cur_name,
  });

  factory MalumotModel.fromJson(Map<String, dynamic> json) {
    return MalumotModel(
      id: json['id'],
      doc_type: json['doc_type'],
      curdate_str: json['curdate_str'],
      curtime_str: json['curtime_str'],
      notes: json['notes'],
      summ: json['summ'],
      summ_uzs: json['summ_uzs'],
      cur_name: json['cur_name'],
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
    map['summ_uzs'] = summ_uzs;
    map['cur_name'] = cur_name;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "id": id,
      "doc_type": doc_type,
      "curdate_str": curdate_str,
      "curtime_str": curtime_str,
      "notes": notes,
      "summ": summ,
      "summ_uzs": summ_uzs,
      "cur_name": cur_name,
    };
  }

  @override
  MalumotModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id']??0;
    doc_type = map['doc_type']??"";
    curdate_str = map['curdate_str']??"";
    curtime_str = map['curtime_str']??"";
    notes = map['notes']??"";
    summ = Utils.checkDouble(map['summ']);
    summ_uzs = Utils.checkDouble(map['summ_uzs']);
    cur_name = map['cur_name']??"";
  }

  String getDocType(BuildContext context) {
    if (doc_type == "order") return AppLocalizations.of(context).translate("dash_ord");
    if (doc_type == "pay") return AppLocalizations.of(context).translate("dash_pay");

    if (doc_type == "payme") return "Payme";
    if (doc_type == "click") return "Click";
    return AppLocalizations.of(context).translate("vitrina");
  }

  @override
  int getId() {
    return 0;
  }

  // MalumotModel.saveFromJsonToDB(Batch bb, String json) {
  //   List list = jsonDecode(json);
  //   if (list.isNotEmpty) {
  //     bb.rawDelete("DELETE FROM dic_cat");
  //   }
  // }
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