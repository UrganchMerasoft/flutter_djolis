import 'dart:convert';

import 'package:flutter_djolis/models/dic_card.dart';
import 'package:flutter_djolis/models/dic_cat.dart';
import 'package:flutter_djolis/models/dic_groups.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:http/http.dart';

import '../core/mysettings.dart';

class DataService {
  static List<DicCatModel> cats = [];
  static List<DicGroups> grp = [];
  static List<DicProd> prods = [];
  static List<NotifModel> notifs = [];
  static List<DicCardModel> cards = [];

  static getCats(List<dynamic> list) {
    cats = list.map((i) => DicCatModel.fromMapObject(i)).toList();
  }

  static getGroups(List<dynamic> list) {
    grp = list.map((i) => DicGroups.fromMapObject(i)).toList();
  }

  static getProds(List<dynamic> list) {
    prods = list.map((i) => DicProd.fromMapObject(i)).toList();
  }

}