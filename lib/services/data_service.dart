import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_djolis/models/dic_card.dart';
import 'package:flutter_djolis/models/dic_cat.dart';
import 'package:flutter_djolis/models/dic_groups.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/juma_model.dart';
import 'package:flutter_djolis/models/malumot_model.dart';
import 'package:flutter_djolis/models/new_click_model.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';

import '../core/mysettings.dart';
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
  static List<JumaModel> juma = [];
  static double cashBack = 0.0;
  static double creditLimit = 0.0;
  static double debt = 0.0;

  static String jumaName = "";
  static double jumaSavdoSumm = 0;
  static double jumaSumm = 0;

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

  static int getJuma(double itogSumm, double savdoSumm, double cashback) {
    if (savdoSumm <= 0) return 0;
    return ((itogSumm / savdoSumm).toInt() * cashback).toInt();
  }

  static Future<void> getAllSettings(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/getall");
    Response? res;
    try {
      res = await post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": device_name,
          "Authorization": "Bearer ${settings.token}",
        },
      );
      debugPrint("$res");
    } catch (e) {
      if (kDebugMode) {
        print("Error data null or data['ok] != 1");
      }
      return;
    }

    if (res.body.toString().contains("Invalid Token...")) {
      settings.logout();
      return;
    }

    Map? data;
    try {
      data = jsonDecode(res.body);
    } catch (e) {
      debugPrint("$e");
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        print("Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {

      DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]);
      DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);

      settings.curRate = Utils.checkDouble(data['d']["settings"]["curRate"]);
      settings.clientId = Utils.checkDouble(data['d']["settings"]["clientId"]).toInt();
      settings.clientName = data['d']["settings"]["clientName"]??"";
      settings.clientFio = data['d']["settings"]["clientFio"]??"";
      settings.clientAddress = data['d']["settings"]["clientAddress"]??"";
      settings.baseName = data['d']["settings"]["baseName"]??"";
      settings.basePhone = data['d']["settings"]["basePhone"]??"";

      settings.firmInn = data['d']["settings"]["firmInn"]??"";
      settings.firmName = data['d']["settings"]["firmName"]??"";
      settings.firmAddress = data['d']["settings"]["firmAddress"]??"";
      settings.firmSchet = data['d']["settings"]["firmSchet"]??"";
      settings.firmBank = data['d']["settings"]["firmBank"]??"";
      settings.firmMfo = data['d']["settings"]["firmMfo"]??"";
      settings.contractNum = data['d']["settings"]["contractNum"]??"";
      settings.contractDate = data['d']["settings"]["contractDate"]??"";
      settings.today = data['d']["settings"]["today"]??"";
      settings.ttClass = data['d']["settings"]["ttClass"]??"";
      settings.minVersion = Utils.checkDouble(data['d']["settings"]["min_version"]).toInt();
      settings.payInfo = data['d']["settings"]["payInfo"]??"";
    }
  }


}
