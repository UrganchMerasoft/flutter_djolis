import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:sms_autodetect/sms_autodetect.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../services/utils.dart';
import '../home/home.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool _first = true;
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

  @override
  void initState() {
    super.initState();
    phoneController.text = "+998977406675";
    codeController.text = "12345";
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return  Container(
      decoration:  const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/splashscreen.jpg"),fit: BoxFit.fill)
      ),
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
                phoneController.selection = TextSelection(baseOffset: 4, extentOffset: phoneController.text.length);
              },
              controller: phoneController,
              validator: (v) => v!.isEmpty ? AppLocalizations.of(context).translate("gl_cannot_empty"): null,
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
                setState(() {});
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

    try {
      final response = await _myHttpPost(settings, settings.token, "${settings.serverUrl}/api-djolis/login",
        {
          "phone": phoneText,
          "code": passwordText,
        },
      );

      if (response == null) {
        showSnackBar(AppLocalizations.of(context).translate("fail_login1"));
        return;
      }

      Map? data;
      data = jsonDecode(response);
      if (data == null) {
        showSnackBar(AppLocalizations.of(context).translate("fail_login2"));
        return;
      }
      if (data["token"] == null) {
        showSnackBar(AppLocalizations.of(context).translate("fail_login3"));
      }

      print("Response: \n\n$response\n\n");

      settings.token = data["token"];
      settings.clientPhone = phoneController.text.trim();
      settings.clientName = data["d"]["name"] ?? '';
      settings.clientFio = data["d"]["contact_fio"] ?? '';
      settings.clientAddress = data["d"]["address"] ?? '';
      await settings.saveAndNotify();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (e) {
      showSnackBar("${AppLocalizations.of(context).translate("error_verify_psw")} $e");
    }
  }

  Future<String?> _myHttpPost(MySettings settings, String token, String url, Map<String, dynamic> body) async {
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName())??"";
    try {
      final response = await http.post(
        Uri.parse(url), headers: {
          "Content-Type": "application/json",
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": phoneController.text,
          "code": codeController.text,
          "device_name": deviceName,
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 202) {
        return response.body;
      } else {
        print("Failed to login: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("HTTP post error: $e");
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
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      margin: EdgeInsets.only(left: 6, right: 6, bottom: MediaQuery.of(context).size.height -80),
    ));
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate("cannot_be_empty");
    } else if (!isValidPhoneNumber(value)) {
      return AppLocalizations.of(context).translate("invalid_number");
    }
    return null;
  }
}
