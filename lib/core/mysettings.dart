import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/models/vitrina.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/utils.dart';


class MySettings with ChangeNotifier {

  static const THEME_AUTO = 0;
  static const THEME_DARK = 1;
  static const THEME_LIGHT = 2;


  static int intVersion = 0;
  static int syncVersion = 0;
  static String version = "";
  static String deviceType = "";
  static double userLatitude = 0;
  static double userLongitude = 0;
  static bool mijozMode = false;

  SharedPreferences prefs;
  int theme = THEME_AUTO;  //0 - auto, 1 - night, 2 - blue (default)
  int language = 0;  //0 - uz, 1 - rus, 2 - eng
  int mainDbId = 0;
  String login = "";
  String token = "";
  double curRate = 1;
  int clientId = 0;
  int mijozId = 0;
  String mijozName = "";
  String mijozPhone = "";
  String mijozAddress = "";
  double mijozGpsLat = 0;
  double mijozGpsLng = 0;
  int minVersion = 0;
  String clientPhone = "";
  String clientName = "";
  String clientFio = "";
  String clientAddress = "";

  String firmInn = "";
  String firmName = "";
  String firmAddress = "";
  String firmSchet = "";
  String firmBank = "";
  String firmMfo = "";
  String contractNum = "";
  String contractDate = "";
  String today = "";
  String ordUuid = "";
  String ttClass = "";
  String payInfo = "";
  String botToken = "";
  int botChatId = 0;
  int allowedMijozCount = 0;
  String djolisPayType = "";


  String baseName = "";
  String basePhone = "";
  String serverUrl = "";
  List<CartModel> cartList = [];
  List<VitrinaModel> vitrinaList = [];

  double get itogSumm {
    double d = 0.0;
    for (var c in cartList) {
      d += c.summ;
    }
    return d;
  }

  double get itogCashbackSumm {
    double d = 0.0;
    for (var c in cartList) {
      d += c.cashbackSumm;
    }
    return d;
  }

  double get itogVitrinaSumm {
    double d = 0.0;
    for (var c in vitrinaList) {
      d += c.summ;
    }
    return d;
  }



  ///

  static int timeOut = 0;   //MyHTTP да хар сафар MySettings settings параметр бормаслиги учун
  String themeName = "LightTheme";
  late Locale locale = const Locale("en", "US");
  // late DocumentSnapshot document;


  MySettings(this.prefs) {
    load();
  }

  void load() {
    login = prefs.getString("login")??"";
    deviceType = prefs.getString("deviceType")??"";
    theme = prefs.getInt("theme")??0;
    language = prefs.getInt("language")??0;
    token = prefs.getString("token")??"";
    clientPhone = prefs.getString("clientPhone")??"";
    curRate = prefs.getDouble("curRate")??1.0;
    clientId = prefs.getInt("clientId")??0;
    mijozId = prefs.getInt("mijoz_id")??0;
    mijozName = prefs.getString("mijoz_name")??"";
    mijozPhone = prefs.getString("mijoz_phone")??"";
    mijozAddress = prefs.getString("mijoz_address")??"";
    mijozGpsLat = prefs.getDouble("mijoz_gps_lat")??0.0;
    mijozGpsLng = prefs.getDouble("mijoz_gps_lng")??0.0;
    minVersion = prefs.getInt("minVersion")??0;
    clientName = prefs.getString("clientName")??"";
    clientFio = prefs.getString("clientFio")??"";
    djolisPayType = prefs.getString("djolisPayType")??"";
    clientAddress = prefs.getString("clientAddress")??"";
    baseName = prefs.getString("baseName")??"";
    payInfo = prefs.getString("payInfo")??"";
    botToken = prefs.getString("botToken")??"";
    botChatId = prefs.getInt("botChatId")??0;
    allowedMijozCount = prefs.getInt("allowedMijozCount")??0;
    ordUuid = prefs.getString("ordUuid")??"";
    basePhone = prefs.getString("basePhone")??"";
    serverUrl = prefs.getString("serverUrl")??"";
    mijozMode = prefs.getBool("mijozMode")??false;
    if (prefs.getString("cartList") != null) {
      cartList = CartModel.fromJsonList(jsonDecode(prefs.getString("cartList") ?? ""));
    }
    if (prefs.getString("vitrinaList") != null) {
      vitrinaList = VitrinaModel.fromJsonList(jsonDecode(prefs.getString("vitrinaList") ?? ""));
    }



    timeOut = prefs.getInt("timeOut")??0;
    mainDbId = prefs.getInt("mainDbId")??0;
    themeName = prefs.getString("themeName")??"LightTheme";
    locale = Locale(prefs.getString("locale_en")??"en", prefs.getString("locale_US")??"US");
  }


  saveAndNotify() async {
    await save();
    notifyListeners();
  }

  save() async {
    await prefs.setString("login", login);
    await prefs.setString("deviceType", deviceType);
    await prefs.setInt("theme", theme);
    await prefs.setInt("language", language);
    await prefs.setString("token", token);
    await prefs.setString("clientPhone", clientPhone);
    await prefs.setDouble("curRate", curRate);
    await prefs.setInt("clientId", clientId);
    await prefs.setInt("mijoz_id", mijozId);
    await prefs.setString("mijoz_name", mijozName);
    await prefs.setString("mijoz_phone", mijozPhone);
    await prefs.setString("mijoz_address", mijozAddress);
    await prefs.setDouble("mijoz_gps_lat", mijozGpsLat);
    await prefs.setDouble("mijoz_gps_lng", mijozGpsLng);
    await prefs.setInt("minVersion", minVersion);
    await prefs.setString("clientName", clientName);
    await prefs.setString("clientFio", clientFio);
    await prefs.setString("djolisPayType", djolisPayType);
    await prefs.setString("clientAddress", clientAddress);
    await prefs.setString("baseName", baseName);
    await prefs.setString("payInfo", payInfo);
    await prefs.setString("botToken", botToken);
    await prefs.setInt("botChatId", botChatId);
    await prefs.setInt("allowedMijozCount", allowedMijozCount);
    await prefs.setString("ordUuid", ordUuid);
    await prefs.setString("basePhone", basePhone);
    await prefs.setString("serverUrl", serverUrl);
    await prefs.setBool("mijozMode", mijozMode);
    await prefs.setString("cartList", jsonEncode(cartList));
    await prefs.setString("vitrinaList", jsonEncode(vitrinaList));


    await prefs.setInt("timeOut", timeOut);
    await prefs.setInt("mainDbId", mainDbId);
    await prefs.setString("themeName", themeName);
    await prefs.setString("locale_en", locale.languageCode);
    await prefs.setString("locale_US", locale.countryCode??"US");
  }

  logout() {
    mainDbId = 0;
    clientPhone = "";
    token = "";
    cartList.clear();
    saveAndNotify();
  }

  String getLangText(BuildContext context) {
    if (language == THEME_AUTO) return "UZ";
    if (language == THEME_DARK) return "RU";
    if (language == THEME_LIGHT) return "EN";
    return "";
  }

  Map<String, String> httpHeaderDateNow() {
    return Utils.httpSimpleJsonHeader("Bearer ${token}", DateTime.now(), "");
  }
}