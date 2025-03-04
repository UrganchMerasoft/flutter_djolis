import 'dart:convert';

import 'package:flutter_djolis/models/dic_card.dart';
import 'package:flutter_djolis/models/dic_cat.dart';
import 'package:flutter_djolis/models/dic_groups.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/malumot_model.dart';
import 'package:flutter_djolis/models/new_click_model.dart';
import 'package:flutter_djolis/models/notif.dart';

import '../models/news.dart';

class DataService {
  static List<DicCatModel> cats = [];
  static List<DicGroups> grp = [];
  static List<DicProd> prods = [];
  static List<NotifModel> notifs = [];
  static List<MalumotModel> malumot = [];
  static List<NewClickModel> newClick = [];
  static List<DicCardModel> cards = [];
  static List<NewsModel> newsList = [];
  static List<NotifModel> notifsList = [];
  static double cashBack = 0.0;
  static double creditLimit = 0.0;
  static double debt = 0.0;

  static getCats(List<dynamic> list) {
    cats = list.map((i) => DicCatModel.fromMapObject(i)).toList();
  }

  static getGroups(List<dynamic> list) {
    grp = list.map((i) => DicGroups.fromMapObject(i)).toList();
  }

  static getProds(List<dynamic> list) {
    prods = list.map((i) => DicProd.fromMapObject(i)).toList();
  }

  static getMalumot(List<dynamic> list) {
    malumot = list.map((i) => MalumotModel.fromMapObject(i)).toList();
  }

  static getNewClick(List<dynamic> list) {
    newClick = list.map((i) => NewClickModel.fromMapObject(i)).toList();
  }

  static void saveNotifs(List<dynamic> list) {
    notifsList = list.map((e) => NotifModel.fromMapObject(e)).toList();
  }

}