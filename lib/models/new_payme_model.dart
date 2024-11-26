import 'package:flutter_djolis/models/my_table.dart';

class NewPaymeModel extends MyTable{

  late String url;

  NewPaymeModel({

    required this.url,
  });


  @override
  String toString() {
    return 'NewClickModel{url: $url}';}

  factory NewPaymeModel.fromJson(Map<String, dynamic> json) {
    return NewPaymeModel(
      url: json["url"]??"",
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['url']=url;

    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "url":url,
    };
  }

  @override
  NewPaymeModel.fromMapObject(Map<String, dynamic> map) {
    url = map["url"]??"";
  }

  @override
  int getId() {
    return 0;
  }

  @override
  String getTableName() {
    throw UnimplementedError();
  }


}