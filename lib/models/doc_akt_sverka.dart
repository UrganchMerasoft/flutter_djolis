
import 'package:flutter_djolis/services/utils.dart';

class DocAktSverka {
  late int id;
  late String docType;
  late String docNum;
  late double summ;
  late String notes;
  late String returnType;
  late int baseId;
  late String baseName;
  late String deliverName;
  late int isNal;
  late int isBn;
  late String enteredTime;
  late String pay_type;
  late double balans;
  late int whInvId;
  late String bank_info;

  DocAktSverka({
    required this.id,
    required this.docType,
    required this.docNum,
    required this.summ,
    required this.notes,
    required this.returnType,
    required this.baseId,
    required this.baseName,
    required this.deliverName,
    required this.isNal,
    required this.isBn,
    required this.enteredTime,
    required this.pay_type,
    required this.balans,
    required this.whInvId,
    required this.bank_info
  });

  @override
  String toString() {
    return 'DocAktSverka{id: $id, docType: $docType, docNum: $docNum, summ: $summ, notes: $notes, returnType: $returnType, baseId: $baseId, baseName: $baseName, deliverName: $deliverName, isNal: $isNal, isBn: $isBn, enteredTime: $enteredTime, balans: $balans, whinvId: $whInvId, bank_info: $bank_info}';
  }

  factory DocAktSverka.fromJson(Map<String, dynamic> json) {
    return DocAktSverka(
      id: json['id'],
      docType: json['doc_type'],
      docNum: json['doc_num'],
      summ: json['summ'],
      notes: json['notes'],
      returnType: json['return_type'],
      baseId: json['base_id'],
      baseName: json['base_name'],
      deliverName: json['deliver_name'],
      isNal: json['is_nal'],
      isBn: json['is_bn'],
      enteredTime: json['entered_time'],
      pay_type: json['pay_type'],
      balans: json['balans'],
      whInvId: json['whInvId'],
      bank_info: json['bank_info'],
    );
  }

  Map<String, dynamic> toMap()=>{
    "id":id,
    "doc_type":docType,
    "doc_num":docNum,
    "summ":summ,
    "notes":notes,
    "return_type":returnType,
    "base_id":baseId,
    "base_name":baseName,
    "deliver_name":deliverName,
    "is_nal":isNal,
    "is_bn":isBn,
    "entered_time":enteredTime,
    "pay_type":pay_type,
    "balans":balans,
    "whInvId":whInvId,
    "bank_info":bank_info,
  };

  Map<String, dynamic> toJson()=>{
    "id":id,
    "doc_type":docType,
    "doc_num":docNum,
    "summ":summ,
    "notes":notes,
    "return_type":returnType,
    "base_id":baseId,
    "base_name":baseName,
    "deliver_name":deliverName,
    "is_nal":isNal,
    "is_bn":isBn,
    "entered_time":enteredTime,
    "pay_type":pay_type,
    "balans":balans,
    "whInvId":whInvId,
    "bank_info":bank_info,
  };

  DocAktSverka.fromMapObject(Map<String, dynamic> map){
    id = map['id'] ?? 0;
    docType = map['doc_type'] ?? "";
    docNum = map['doc_num'] ?? "";
    summ = Utils.checkDouble(map['summ']);
    notes = map['notes'] ?? "";
    returnType = map['return_type'] ?? "";
    baseId = map['base_id'] ?? 0;
    baseName = map['base_name'] ?? "";
    deliverName = map['deliver_name'] ?? "";
    isNal = map['is_nal'] ?? 0;
    isBn = map['is_bn'] ?? 0;
    enteredTime = map['entered_time']?? "";
    pay_type = map['pay_type']?? "";
    balans = Utils.checkDouble(map['balans']);
    whInvId = Utils.checkDouble(map['whinv_id']).toInt();
    bank_info = map['bank_info']?? "";
  }
}
