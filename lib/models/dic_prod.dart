import 'package:flutter_djolis/services/utils.dart';

class DicProd {

  late int id;
  late String catName;
  late int groupId;
  late String name;
  late String nameForSearch;
  late String unit1;
  late String unit2;
  late int coeff;
  late String brand;
  late double price;
  late double cashbackProcent;
  late int rating;
  late int ratingOrders;
  late int isFamous;
  late String similarProdIds;
  late double ostQty;
  late String ostQtyText;
  late String info;
  late String picUrl;
  late String videoUrl;
  late String infoPicUrl;
  late int hasVitrina;
  late int forVitrina;
  late double prevOstVitrina;
  late double ostVitrina;
  late double savdoVitrina;
  late double savdoVitrinaSumm;

  late double orderQty;
  late double orderSumm;
  late double cashbackSumm;

  String get getOrderQty {
    if (coeff == 1000) {
      return "${Utils.myNumFormat0(orderQty)} $unit2";
    }
    return "${Utils.myNumFormat0(orderQty)} $unit1";
  }

  DicProd({
    required this.id,
    required this.catName,
    required this.groupId,
    required this.name,
    required this.nameForSearch,
    required this.unit1,
    required this.unit2,
    required this.coeff,
    required this.brand,
    required this.price,
    required this.cashbackProcent,
    required this.rating,
    required this.ratingOrders,
    required this.isFamous,
    required this.similarProdIds,
    required this.orderQty,
    required this.orderSumm,
    required this.ostQty,
    required this.ostQtyText,
    required this.info,
    required this.picUrl,
    required this.videoUrl,
    required this.infoPicUrl,
    required this.hasVitrina,
    required this.forVitrina,
    required this.prevOstVitrina,
    required this.ostVitrina,
    required this.savdoVitrina,
    required this.savdoVitrinaSumm,
  });

  factory DicProd.fromJson(Map<String, dynamic> json) {
    return DicProd(
      id: json['id'] ?? 0,
      catName: json['catname'] ?? "?",
      groupId: json['groupId'] ?? 0,
      name: json['name'] ?? "?",
      nameForSearch: json['nameForSearch'] ?? "?",
      unit1: json['unit1'] ?? "?",
      unit2: json['unit2'] ?? "?",
      coeff: json['coeff'] ?? 0,
      brand: json['brand'] ?? "?",
      price: json['price'] ?? 0.0,
      cashbackProcent: json['cashbackProcent'] ?? 0.0,
      rating: json['rating'] ?? 0,
      ratingOrders: json['ratingOrders'] ?? 0,
      isFamous: json['isFamous'] ?? 0,
      similarProdIds: json['similarProdIds'] ?? 0,
      orderQty: json['orderQty'] ?? 0,
      orderSumm: json['orderSumm'] ?? 0,
      ostQty: json['ostQty'] ?? 0.0,
      ostQtyText: json['ostQtyText'],
      info: json['info'],
      picUrl: json['picUrl'],
      videoUrl: json['videoUrl'],
      infoPicUrl: json['infoPicUrl'],
      hasVitrina: json['hasVitrina'],
      forVitrina: json['forVitrina'],
      prevOstVitrina: json['prevOstVitrina'],
      ostVitrina: json['ostVitrina'],
      savdoVitrina: json['savdoVitrina'],
      savdoVitrinaSumm: json['savdoVitrinaSumm'],
    );
  }



  Map<String, dynamic> toMap()=>{
    'id':id,
    'catName':catName,
    'groupId':groupId,
    'name':name,
    'nameForSearch':nameForSearch,
    'unit1':unit1,
    'unit2':unit2,
    'coeff':coeff,
    'brand':brand,
    'price':price,
    'cashbackProcent':cashbackProcent,
    'rating':rating,
    'ratingOrders':ratingOrders,
    'isFamous':isFamous,
    'similarProdIds':similarProdIds,
    'orderQty':orderQty,
    'orderSumm':orderSumm,
    'ostQty':ostQty,
    'ostQtyText':ostQtyText,
    'info':info,
    'picUrl': picUrl,
    'videoUrl': videoUrl,
    'infoPicUrl':infoPicUrl,
    'hasVitrina':hasVitrina,
    'forVitrina':forVitrina,
    'prevOstVitrina':prevOstVitrina,
    'ostVitrina':ostVitrina,
    'savdoVitrina':savdoVitrina,
    'savdoVitrinaSumm':savdoVitrinaSumm,
  };

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "catName":catName,
      "groupId":groupId,
      "name":name,
      "nameForSearch":nameForSearch,
      "unit1":unit1,
      "unit2":unit2,
      "coeff":coeff,
      "brand":brand,
      "price":price,
      "cashbackProcent":cashbackProcent,
      "rating":rating,
      "ratingOrders":ratingOrders,
      "isFamous":isFamous,
      "similarProdIds":similarProdIds,
      "orderQty":orderQty,
      "orderSumm":orderSumm,
      "ostQty":ostQty,
      "ostQtyText":ostQtyText,
      "info":info,
      "picUrl":picUrl,
      "videoUrl":videoUrl,
      "infoPicUrl":infoPicUrl,
      "hasVitrina":hasVitrina,
      "forVitrina":forVitrina,
      "prevOstVitrina":prevOstVitrina,
      "ostVitrina":ostVitrina,
      "savdoVitrina":savdoVitrina,
      "savdoVitrinaSumm":savdoVitrinaSumm,
    };
  }

  DicProd.fromMapObject(Map<String, dynamic> map){
    id = map['id'] ?? 0;
    catName = map['catName'] ?? "?";
    groupId = map['groupId'] ?? 0;
    name = map['name'] ?? "?";
    nameForSearch = map['nameForSearch'] ?? "?";
    unit1 = map['unit1'] ?? "?";
    unit2 = map['unit2'] ?? "?";
    coeff = map['coeff'] ?? 0;
    brand = map['brand'] ?? "?";
    price = Utils.checkDouble(map['price']);
    cashbackProcent = Utils.checkDouble(map['cashbackProcent']);
    rating = map['rating'] ?? 0;
    ratingOrders = map['ratingOrders'] ?? 0;
    isFamous = map['isFamous'] ?? 0;
    similarProdIds = map['similarProdIds'] ?? "";
    orderQty = Utils.checkDouble(map['orderQty']);
    orderSumm = Utils.checkDouble(map['orderSumm']);
    ostQty = Utils.checkDouble(map['ostQty']);
    ostQtyText = map['ostQtyText'] ?? "";
    info = map['info'] ?? "";
    picUrl = map['picUrl'] ?? "";
    videoUrl = map['videoUrl'] ?? "";
    infoPicUrl = map['infoPicUrl'] ?? "";
    hasVitrina = Utils.checkDouble(map['hasVitrina']).toInt();
    forVitrina = Utils.checkDouble(map['forVitrina']).toInt();
    prevOstVitrina = Utils.checkDouble(map['prevOstVitrina']);
    ostVitrina = Utils.checkDouble(map['ostVitrina']);
    savdoVitrina = Utils.checkDouble(map['savdoVitrina']);
    savdoVitrinaSumm = Utils.checkDouble(map['savdoVitrinaSumm']);
  }
}
