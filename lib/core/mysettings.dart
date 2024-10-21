import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_localizations.dart';
import '../services/utils.dart';


class MySettings with ChangeNotifier {

  static const THEME_AUTO = 0;
  static const THEME_DARK = 1;
  static const THEME_LIGHT = 2;


  static int syncVersion = 0;
  static String version = "";

  SharedPreferences prefs;
  int theme = THEME_AUTO;  //0 - auto, 1 - night, 2 - blue (default)
  int language = 0;  //0 - uz, 1 - rus, 2 - eng
  int mainDbId = 0;
  String login = "";
  String token = "";
  int clientId = 0;
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

  String baseName = "";
  String basePhone = "";
  String serverUrl = "";
  List<CartModel> cartList = [];
  double get itogSumm {
    double d = 0.0;
    for (var c in cartList) {
      d += c.summ;
    }
    return d;
  }



  ///

  static int timeOut = 0;   //MyHTTP да хар сафар MySettings settings параметр бормаслиги учун
  String themeName = "LightTheme";
  late Locale locale = const Locale("uz", "UZ");
  // late DocumentSnapshot document;


  MySettings(this.prefs) {
    load();
  }

  void load() {
    login = prefs.getString("login")??"";
    theme = prefs.getInt("theme")??0;
    language = prefs.getInt("language")??0;
    token = prefs.getString("token")??"";
    clientPhone = prefs.getString("clientPhone")??"";
    clientId = prefs.getInt("clientId")??0;
    clientName = prefs.getString("clientName")??"";
    clientFio = prefs.getString("clientFio")??"";
    clientAddress = prefs.getString("clientAddress")??"";
    baseName = prefs.getString("baseName")??"";
    basePhone = prefs.getString("basePhone")??"";
    serverUrl = prefs.getString("serverUrl")??"";
    if (prefs.getString("cartList") != null) {
      cartList = CartModel.fromJsonList(jsonDecode(prefs.getString("cartList") ?? ""));
    }


    timeOut = prefs.getInt("timeOut")??0;
    mainDbId = prefs.getInt("mainDbId")??0;
    themeName = prefs.getString("themeName")??"LightTheme";
    locale = Locale(prefs.getString("locale_en")??"ru", prefs.getString("locale_US")??"RU");
  }


  saveAndNotify() async {
    await save();
    notifyListeners();
  }

  save() async {
    await prefs.setString("login", login);
    await prefs.setInt("theme", theme);
    await prefs.setInt("language", language);
    await prefs.setString("token", token);
    await prefs.setString("clientPhone", clientPhone);
    await prefs.setInt("clientId", clientId);
    await prefs.setString("clientName", clientName);
    await prefs.setString("clientFio", clientFio);
    await prefs.setString("clientAddress", clientAddress);
    await prefs.setString("baseName", baseName);
    await prefs.setString("basePhone", basePhone);
    await prefs.setString("serverUrl", serverUrl);
    await prefs.setString("cartList", jsonEncode(cartList));


    ///

    await prefs.setInt("timeOut", timeOut);
    await prefs.setInt("mainDbId", mainDbId);
    await prefs.setString("themeName", themeName);
    await prefs.setString("locale_en", locale.languageCode);
    await prefs.setString("locale_US", locale.countryCode??"RU");
  }


  logout() {
    mainDbId = 0;
    //fireUser = "";
    clientPhone = "";
    token = "";

    saveAndNotify();
  }
  // String getThemeText(BuildContext context) {
  //   if (theme == THEME_AUTO) return AppLocalizations.of(context).translate("auto");
  //   if (theme == THEME_DARK) return AppLocalizations.of(context).translate("dark");
  //   if (theme == THEME_LIGHT) return AppLocalizations.of(context).translate("light");
  //   return "";
  // }
  //
  // String getLangText(BuildContext context) {
  //   if (language == THEME_AUTO) return AppLocalizations.of(context).translate("uzbek");
  //   if (language == THEME_DARK) return AppLocalizations.of(context).translate("russian");
  //   if (language == THEME_LIGHT) return AppLocalizations.of(context).translate("english");
  //   return "";
  // }

  Map<String, String> httpHeaderDateNow() {
    return Utils.httpSimpleJsonHeader("Bearer ${token}", DateTime.now(), "");
  }
}