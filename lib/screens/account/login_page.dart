import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../services/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  FocusNode codeFocus = FocusNode();
  String phone = "";
  String server = "";
  String serverName = "";
  String errorMsg = "";
  bool _isLoading = false;
  bool _obscureText = true;
  Timer? timer;

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
            const SizedBox(
              height: 30,
            ),
            TextFormField(
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              onTap: (){
              },
              controller: phoneController,
              // validator: (v) {
              //   if(v!.isEmpty){
              //     return AppLocalizations.of(context).translate("enter_summ");
              //   }else{
              //     return null;
              //   }
              // },
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
              focusNode: codeFocus,
              validator: null,
              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
              textInputAction: TextInputAction.done,
              obscureText: _obscureText,
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
      await settings.saveAndNotify();
    } catch (e) {
      showSnackBar("${AppLocalizations.of(context).translate("error_verify_psw")} $e");
    }
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
}
