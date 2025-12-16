import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../services/firebase_api.dart';
import '../../services/local_notification_service.dart';
import '../../services/utils.dart';
import '../../wrapper.dart';
import '../home/home.dart';
import '../mijoz_screens/mijoz_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController clientCodeController = TextEditingController();
  FocusNode codeFocus = FocusNode();
  FocusNode clientCodeFocus = FocusNode();
  String phone = "";
  String server = "";
  String serverName = "";
  String errorMsg = "";
  bool _isLoading = false;
  Timer? timer;
  bool _isButtonVisible = false;

  String uzbUrl = "http://212.109.199.213:3143";
  String dubaiUrl = "http://212.109.199.213:3147";

  String getServerUrl(String phoneNumber) {
    if (phoneNumber.startsWith('+998')) {
      return uzbUrl;
    } else if (phoneNumber.startsWith('+971')) {
      return dubaiUrl;
    } else {
      debugPrint("Invalid server URL");
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      LocalNotificationService.initialize();
      await FirebaseApi().initNotifications();
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    });
    _checkVisibilityStatus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/splashscreen.jpg"), fit: BoxFit.fill)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: getPhoneBody(settings),
                ),
              ),
              Text("Version: ${MySettings.intVersion}.0.0", style: TextStyle(color: Colors.grey.shade400, fontSize: 12),),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget getPhoneBody(MySettings settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
             Padding(
               padding: const EdgeInsets.only(left: 260),
               child: InkWell(
                 onTap: (){
                   selectLang(context, settings);
                 },
                 child: Row(
                   children: [
                    const Icon(Icons.language, color: Colors.white,),
                     const SizedBox(width: 5),
                     Text(settings.getLangText(context), style: const TextStyle(color: Colors.white),),
                   ],
                 ),
               ),
             ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 72, 0, 0),
              child: Image.asset("assets/images/djolis_logo.png",height: 124, width: 200,),
            ),
            const SizedBox(height: 30),
            TextFormField(
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              onTap: (){
              },
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                fillColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white.withOpacity(0.1),
                isDense: true,
                prefixStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                labelText: AppLocalizations.of(context).translate("new_account_phone"),
                labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),
                contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                focusColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white,
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),borderRadius: BorderRadius.circular(10)),
                border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
                enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              onTap: (){
                codeController.selection = TextSelection(baseOffset: 0, extentOffset: codeController.text.length);
              },
              controller: codeController,
              obscureText: true,
              focusNode: codeFocus,
              validator: null,
              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                fillColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white.withOpacity(0.1), //const Color.fromRGBO(94, 36, 66, 0.1),
                isDense: true,
                prefixStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                labelText: AppLocalizations.of(context).translate("new_account_password"),
                labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),
                contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                focusColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white,
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),borderRadius: BorderRadius.circular(10)),
                border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
                enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), shape:  RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              )),
              onPressed: () async {
                _isLoading = true;
                await verifyPassword(settings);
                if(mounted){
                  setState(() {});
                }
              },
              child: _isLoading ? const SpinKitCircle(color: Colors.white, size: 25.0) : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(visible: _isLoading, child: const SpinKitCircle(color: Colors.white, size: 25.0)),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).translate("new_account_send_sms"), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),),
                ],
              ),
            )),
            const SizedBox(height: 60),
            SizedBox(
              height: 50,
              width: 235,
              child: Visibility(
                visible: _isButtonVisible,
                child: TextButton(
                  onPressed: () async {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return loginAsClientDialog(settings);
                        },
                      );
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context).translate("enter_as_a_client"),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> verifyPassword(MySettings settings) async {
    String phoneText = phoneController.text.trim();
    String passwordText = codeController.text.trim();

    if (phoneText.isEmpty) {
      showSnackBar(AppLocalizations.of(context).translate("enter_phone_psw"));
      return;
    }

    if (!isValidPhoneNumber(phoneText)) {
      showSnackBar(AppLocalizations.of(context).translate("invalid_number"));
      return;
    }

    settings.serverUrl = getServerUrl(phoneText);
    if (settings.serverUrl.isEmpty) {
      showSnackBar(AppLocalizations.of(context).translate("invalid_number"));
      return;
    }
    settings.saveAndNotify();

    try {
      final response = await _myHttpPost(settings, settings.token, "${settings.serverUrl}/api-djolis/login", {
        "phone": phoneText,
        "code": passwordText,
      });

      if (response == null) {
        showSnackBar(AppLocalizations.of(context).translate("fail_login1"));
        return;
      }

      Map? data = jsonDecode(response);
      if (data == null || data["token"] == null) {
        showSnackBar(AppLocalizations.of(context).translate("fail_login2"));
        return;
      }

      settings.token = data["token"];
      settings.clientPhone = phoneText;
      settings.clientName = data["d"]["name"] ?? '';
      settings.clientFio = data["d"]["contact_fio"] ?? '';
      settings.clientAddress = data["d"]["address"] ?? '';
      MySettings.mijozMode = false;
      await settings.saveAndNotify();
    } catch (e) {
      showSnackBar("${AppLocalizations.of(context).translate("error_verify_psw")} $e");
    }
  }

 AlertDialog loginAsClientDialog(MySettings settings) {
  return AlertDialog(
    backgroundColor: Theme.of(context).primaryColor,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppLocalizations.of(context).translate("enter_as_a_client"), style: const TextStyle(color: Colors.white)),
        IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.cancel, color: Colors.white),)
      ],
    ),
    titlePadding: const EdgeInsets.only(top:20, left: 24, right: 10),
    actionsPadding: const EdgeInsets.all(20),
    actions: [
      Column(
        children: [
          TextFormField(
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            controller: clientCodeController,
            focusNode: clientCodeFocus,
            validator: null,
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: InputDecoration(
              fillColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white.withOpacity(0.1), //const Color.fromRGBO(94, 36, 66, 0.1),
              isDense: true,
              prefixStyle: TextStyle(color: Theme.of(context).colorScheme.error),
              labelText: AppLocalizations.of(context).translate("enter_temp_code"),
              labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),
              contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
              focusColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white,
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white),borderRadius: BorderRadius.circular(10)),
              border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
              enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.white),borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), shape:  RoundedRectangleBorder(
              side: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            )),
            onPressed: () async {

              await verifyMijoz(settings, clientCodeController.text.trim());

              if (mounted && settings.token.isNotEmpty) {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Wrapper()));
              }
            },

            child: _isLoading ? const SpinKitCircle(color: Colors.white, size: 25.0) : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Visibility(visible: _isLoading, child: const SpinKitCircle(color: Colors.white, size: 25.0)),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).translate("new_account_send_sms"), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),),
              ],
            ),
          )),
        ],
      ),
    ],
  );

}

  Future<String?> _myHttpPost(MySettings settings, String token, String url, Map<String, dynamic> body) async {
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName()) ?? "";
    try {
      final response = await http.post(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": phoneController.text,
        "code": codeController.text,
        "device_name": deviceName,
        "Authorization": "Bearer $token",
      }, body: json.encode(body));
      if (response.statusCode == 200 || response.statusCode == 202) {
        return response.body;
      } else {
        debugPrint("Failed to login: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("HTTP post error: $e");
      return null;
    }
  }

  Future<void> verifyMijoz(MySettings settings, String code) async {
    // try {
      final response = await _myMijozHttpPost(settings, settings.token, "http://212.109.199.213:3143/api-djolis/login-mijoz", {
        "code": code,
      });
      if (response == null) {
        debugPrint("response: $response");
        await verifyMijozDubai(settings, clientCodeController.text.trim());
        return;
      }

      Map? data = jsonDecode(response);
      if (data == null || data["token"] == null) {
        debugPrint("data: $data");
        await verifyMijozDubai(settings, clientCodeController.text.trim());
        return;
      }

      settings.serverUrl = "http://212.109.199.213:3143";
      settings.token = data["token"];
      MySettings.mijozMode = true;
      settings.clientName = data["d"]["name"] ?? '';
      settings.clientFio = data["d"]["contact_fio"] ?? '';
      settings.clientAddress = data["d"]["address"] ?? '';
      settings.clientPhone = data["d"]["phone"] ?? '';
      settings.mijozId = data["d"]["mijoz_id"];
      settings.mijozName = data["d"]["mijoz_name"] ?? '';
      settings.mijozPhone = data["d"]["mijoz_phone"] ?? '';
      settings.mijozAddress = data["d"]["mijoz_address"] ?? '';
      settings.mijozGpsLat = Utils.checkDouble(data["d"]["mijoz_gps_lat"]);
      settings.mijozGpsLng = Utils.checkDouble(data["d"]["mijoz_gps_lng"]);
      await settings.saveAndNotify();
    //
    // } catch (e) {
    //   showSnackBar("${AppLocalizations.of(context).translate("error_verify_psw")} $e");
    // }
  }

  Future<void> verifyMijozDubai(MySettings settings, String code) async {
    final response = await _myMijozHttpPost(settings, settings.token, "http://212.109.199.213:3147/api-djolis/login-mijoz", {
      "code": code,
    });
    if (response == null) {
      debugPrint("response: $response");
      showSnackBar(AppLocalizations.of(context).translate("fail_login1"));
      return;
    }

    Map? data = jsonDecode(response);
    if (data == null || data["token"] == null) {
      debugPrint("data: $data");
      showSnackBar(AppLocalizations.of(context).translate("fail_login2"));
      return;
    }

    settings.serverUrl = "http://212.109.199.213:3147";
    settings.token = data["token"];
    MySettings.mijozMode = true;
    settings.clientName = data["d"]["name"] ?? '';
    settings.clientFio = data["d"]["contact_fio"] ?? '';
    settings.clientAddress = data["d"]["address"] ?? '';
    settings.clientPhone = data["d"]["phone"] ?? '';
    settings.mijozId = data["d"]["mijoz_id"];
    settings.mijozName = data["d"]["mijoz_name"] ?? '';
    settings.mijozPhone = data["d"]["mijoz_phone"] ?? '';
    settings.mijozAddress = data["d"]["mijoz_address"] ?? '';
    settings.mijozGpsLat = Utils.checkDouble(data["d"]["mijoz_gps_lat"]);
    settings.mijozGpsLng = Utils.checkDouble(data["d"]["mijoz_gps_lng"]);
    await settings.saveAndNotify();
    //
    // } catch (e) {
    //   showSnackBar("${AppLocalizations.of(context).translate("error_verify_psw")} $e");
    // }
  }

  Future<String?> _myMijozHttpPost(MySettings settings, String token, String url, Map<String, dynamic> body) async {
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName()) ?? "";
    try {
      final response = await http.post(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": "+998977406675",
        "code": "12345",
        "device_name": deviceName,
        "Authorization": "Bearer $token",
      }, body: json.encode(body));
      if (response.statusCode == 200 || response.statusCode == 202) {
        return response.body;
      } else {
        debugPrint("Failed to login: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("HTTP post error: $e");
      return null;
    }
  }


  bool isValidPhoneNumber(String phone) {
    final RegExp phoneRegExp = RegExp(r'^\+(998\d{9}|971\d{8,9})$');
    return phoneRegExp.hasMatch(phone);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ));
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
    ));
  }

  void selectLang(BuildContext context, MySettings settings) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final action = CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                settings.language = 0;
                settings.locale = const Locale("uz", "UZ");
                settings.saveAndNotify();
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context).translate("uzbek"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800),
              )),
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 1;
              settings.locale = const Locale("ru", "RU");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("russian"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800)),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 2;
              settings.locale = const Locale("en", "US");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("english"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(AppLocalizations.of(context).translate("gl_cancel"),
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.green.shade800)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      showCupertinoModalPopup(context: context, builder: (context) => action);
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Text(
                    "🇺🇿",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title: Text(AppLocalizations.of(context).translate("uzbek")),
                  onTap: () {
                    settings.language = 0;
                    settings.locale = const Locale("uz", "UZ");
                    settings.saveAndNotify();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Text(
                    "🇷🇺",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title:
                  Text(AppLocalizations.of(context).translate("russian")),
                  onTap: () {
                    settings.language = 1;
                    settings.locale = const Locale("ru", "RU");
                    settings.saveAndNotify();
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: Text(
                    "🇺🇸",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title:
                  Text(AppLocalizations.of(context).translate("english")),
                  onTap: () {
                    settings.language = 2;
                    settings.locale = const Locale("en", "US");
                    settings.saveAndNotify();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _checkVisibilityStatus() async {

    final now = DateTime.now();

    final hiddenStart = DateTime(2025, 12, 1, 15, 30);   // 1-dekabr 15:30
    final hiddenEnd   = DateTime(2025, 12, 2, 14, 30);   // 2-dekabr 14:30

    if (now.isAfter(hiddenStart) && now.isBefore(hiddenEnd)) {
      _isButtonVisible = false;
    } else {
      _isButtonVisible = true;
    }
    setState(() {});
  }



}
