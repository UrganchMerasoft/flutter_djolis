import 'package:flutter_djolis/models/my_table.dart';

class NewClickModel extends MyTable{

  late int id;
  late String curtime;
  late int click_trans_id;
  late int service_id;
  late int click_paydoc_id;
  late int merchant_id;
  late int merchant_account_id;
  late String merchant_trans_id;
  late int amount;
  late int status_id;
  late String url;

  NewClickModel({
    required this.id,
    required this.curtime,
    required this.click_trans_id,
    required this.service_id,
    required this.click_paydoc_id,
    required this.merchant_id,
    required this.merchant_account_id,
    required this.merchant_trans_id,
    required this.amount,
    required this.status_id,
    required this.url,
});


  @override
  String toString() {
    return 'NewClickModel{id: $id, curtime: $curtime, click_trans_id: $click_trans_id, service_id: $service_id, click_paydoc_id: $click_paydoc_id, merchant_id: $merchant_id, merchant_account_id: $merchant_account_id, merchant_trans_id: $merchant_trans_id, amount: $amount, status_id: $status_id, url: $url}';}

  factory NewClickModel.fromJson(Map<String, dynamic> json) {
    return NewClickModel(
      id: json["id"]??0,
      curtime: json["curtime"]??"",
      click_trans_id: json["click_trans_id"]??0,
      service_id: json["service_id"]??0,
      click_paydoc_id: json["click_paydoc_id"]??0,
      merchant_id: json["merchant_id"]??0,
      merchant_account_id: json["merchant_account_id"]??0,
      merchant_trans_id: json["merchant_trans_id"]??"",
      amount: json["amount"]??0,
      status_id: json["status_id"]??0,
      url: json["url"]??"",
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['id'] = id;
    map['curtime']=curtime;
    map['click_trans_id']=click_trans_id;
    map['service_id']=service_id;
    map['click_paydoc_id']=click_paydoc_id;
    map['merchant_id']=merchant_id;
    map['merchant_account_id']=merchant_account_id;
    map['merchant_trans_id']=merchant_trans_id;
    map['amount']=amount;
    map['status_id']=status_id;
    map['url']=url;

    return map;
  }

  Map<String,dynamic> toJson(){
    return {
      "id": id,
      "curtime":curtime,
      "click_trans_id":click_trans_id,
      "service_id":service_id,
      "click_paydoc_id":click_paydoc_id,
      "merchant_id":merchant_id,
      "merchant_account_id":merchant_account_id,
      "merchant_trans_id":merchant_trans_id,
      "amount":amount,
      "status_id":status_id,
      "url":url,
    };
  }

  @override
  NewClickModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id']??0;
    curtime = map["curtime"]??"";
    click_trans_id = map["click_trans_id"]??0;
    service_id = map["service_id"]??0;
    click_paydoc_id = map["click_paydoc_id"]??0;
    merchant_id = map["merchant_id"]??0;
    merchant_account_id = map["merchant_account_id"]??0;
    merchant_trans_id = map["merchant_trans_id"]??"";
    amount = map["amount"]??0;
    status_id = map["status_id"]??0;
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