import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Utils {

  static final Utils _singleton = Utils._internal();

  static Map<String, String> httpSimpleJsonHeader(String token, DateTime date, String db) => {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": token,
          "db": db,
          "date": date.millisecondsSinceEpoch.toString(),
          "charset": "utf-8"
    };

  static DateFormat formatYYYYMMdd = DateFormat('yyyy-MM-dd');
  static DateFormat formatYYYYMMddhhmm = DateFormat('yyyy-MM-dd HH:mm');
  static DateFormat formatYYYYMMddhhmmForDicProd = DateFormat('yyyyMMddHHmm');
  static DateFormat formatDDMMYYYYhhmm = DateFormat('dd.MM.yyyy HH:mm');
  static DateFormat formatDDMMYYYYhhmmss = DateFormat('dd.MM.yyyy HH:mm:ss');
  static DateFormat formatDDMM = DateFormat('dd.MM');
  static DateFormat formatDDMMYYY = DateFormat('dd.MM.yyyy');

  static DateFormat formatHHMM = DateFormat('HH:mm');
  static NumberFormat numFormat0_00 = NumberFormat.simpleCurrency(name: "", decimalDigits: 2, locale: 'ru');
  static NumberFormat numFormat0 = NumberFormat.simpleCurrency(name: "", decimalDigits: 0, locale: 'ru');

  static NumberFormat numFormatCurrent = NumberFormat.simpleCurrency(name: "", decimalDigits: 0, locale: 'ru');



  static String myDateFormat(DateFormat f, DateTime val) {
    return f.format(val);
  }

  static String myDateFormatFromInt(DateFormat f, int val) {
    if (val == 0) return "";
    return f.format(DateTime.fromMillisecondsSinceEpoch(val*1000));
  }

  static String myDateFormatFromStr(DateFormat f, String val) {
    return f.format(DateTime.fromMillisecondsSinceEpoch(int.parse(val)*1000));
  }


  static String myNumFormat(NumberFormat f, double d) {
    if (d == 0) {
      return "-";
    }
    return f.format(d);
  }

  static String myNumFormat2(double d) {
    if (d == 0) {
      return "-";
    }
    if (d == d.roundToDouble()) {
      return Utils.numFormat0.format(d);
    } else {
      return Utils.numFormat0_00.format(d);
    }
  }

  static String myNumFormat0(double d) {
    if (d == 0) {
      return "0";
    }
    return Utils.numFormatCurrent.format(d);
  }

  static String myNumFormat00(double d) {
    if (d == 0) {
      return "0";
    }
    return Utils.numFormat0_00.format(d);
  }


  static String myUUID() {
    return const Uuid().v1();
  }

  static double dp(double val, int places){
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }


  Future<String?> getDeviceId() async {
    String deviceId = "";
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
        deviceId = build.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo build = await deviceInfoPlugin.iosInfo;
        deviceId = build.identifierForVendor??"????";
      }
      return deviceId;
    }  catch(e) {
      debugPrint("Error on getting device Info.$e");
    }
    return null;
  }

  static Future<String?> getDeviceName() async {
    String deviceName = "";
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
        deviceName = build.device;
      } else if (Platform.isIOS) {
        IosDeviceInfo build = await deviceInfoPlugin.iosInfo;
        deviceName = build.name;
      }
      return deviceName;
    }  catch(e) {
      debugPrint("Error on getting device Info.$e");
    }
    return null;
  }

  static double checkDouble(dynamic value) {
    if (value == null) {
      return 0.00;
    }

    if (value is String) {
      if (value.replaceAll(" ", "").replaceAll(" ", "") == "") {
        return 0.0;
      }

      return double.parse(value.replaceAll(" ", "").replaceAll(" ", ""));
    } else {
      if (value is int) {
        return value+0.0;
      } else {
        return value;
     }
   }
  }

  static List<String> get days {
    return ['Все', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  }

  factory Utils() {
    return _singleton;
  }

  Utils._internal();

  static double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));

  }

  static int getDateInt() {
    DateTime now = DateTime.now();
    DateTime d = DateTime(now.year, now.month, now.day);
    int inSeconds = d.millisecondsSinceEpoch ~/ 1000;
    return inSeconds;
  }

  static DateTime getDate() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static int getNowInt() {
    double inSeconds = (DateTime.now()).millisecondsSinceEpoch / 1000;
    return inSeconds.toInt();
  }

  static DateTime getNow() {
    return DateTime.now();
  }

  static urlModifier(String url) {
    if (url.contains("?")) {
      return url + "&";
    }
    return url + "?";
  }

  static Future<String> getToken() async {
    String fcmToken =  (await FirebaseMessaging.instance.getToken()) ?? "";
    if (Platform.isIOS && fcmToken.isEmpty) {
      fcmToken = (await FirebaseMessaging.instance.getAPNSToken()) ?? "";
    }
    return fcmToken;
  }
}