import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'my_table.dart';

class NotifModel extends MyTable {
  late int id;
  late String curtime;
  late String msg;
  late String msg_title;
  late String pic_url;
  late bool has_read;
  late int is_tezol;

  NotifModel({
    required this.id,
    required this.curtime,
    required this.msg,
    required this.msg_title,
    required this.pic_url,
    required this.has_read,
    required this.is_tezol,
  });

  factory NotifModel.fromJson(Map<String, dynamic> json) {
    return NotifModel(
      id: json['id'],
      curtime: json['curtime'],
      msg: json['msg'],
      msg_title: json['msg_title'],
      pic_url: json['pic_url'],
      has_read: json['has_read'],
      is_tezol: json['is_tezol'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['id'] = id;
    map['curtime'] = curtime;
    map['msg'] = msg;
    map['msg_title'] = msg_title;
    map['pic_url'] = pic_url;
    map['has_read'] = has_read;
    map['is_tezol'] = is_tezol;
    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "id": id,
      "curtime": curtime,
      "msg": msg,
      "msg_title": msg_title,
      "pic_url": pic_url,
      "is_tezol": is_tezol,
    };
  }

  @override
  NotifModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id']??0;
    curtime = map['curtime']??"";
    msg = map['msg']??"";
    msg_title = map['msg_title']??"";
    pic_url = map['pic_url']??"";
    has_read = (map['has_read']??0) == 1;
    is_tezol = map['is_tezol']??0;
  }

  @override
  int getId() {
    return 0;
  }

  // NotifModel.saveFromJsonToDB(Batch bb, String json) {
  //   List list = jsonDecode(json);
  //   if (list.isNotEmpty) {
  //     bb.rawDelete("DELETE FROM dic_cat");
  //   }
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