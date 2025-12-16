import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/mysettings.dart';
import '../../../models/dic_clients.dart';
import '../../../services/utils.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  bool _isLoading = false;
  List<DicClients> clients = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController pswController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllClients(settings);
    });
  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/back_wallpaper.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate("clients"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => addClientDialog(settings, 2),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator( color: Colors.white,))
                      : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          nameController.text = clients[index].name;
                          phoneController.text = clients[index].phone;
                          pswController.text = clients[index].psw;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => addClientDialog(settings, 1, clientId: clients[index].id),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Slidable(
                            endActionPane: ActionPane(
                              extentRatio: 0.20,
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  borderRadius: BorderRadius.circular(16),
                                  backgroundColor: Colors.green.withOpacity(0.8),
                                  icon: Icons.password_sharp,
                                  label: "Code",
                                  onPressed: (BuildContext context1) async {
                                    Future.delayed(const Duration(milliseconds: 200), () async {
                                      await generateCode(context, settings, clients[index].id);
                                    });
                                  },
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                clients[index].name,
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: Theme.of(context).primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.phone,
                                                color:Theme.of(context).primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              clients[index].phone,
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> getAllClients(MySettings settings) async {

    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    setState(() {
      _isLoading = true;
    });
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-get");
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint("getAll Error 1 data null or data['ok] != 1");
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
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint("getAll 2 Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      final List<dynamic> clientsData = data['d'] ?? [];
      clients = clientsData.map((item) => DicClients.fromMapObject(item)).toList();
      debugPrint("Clients: $clients");
      setState(() {});

      if(mounted){
        setState(() {
          _isLoading = false;
        });

      }
    }
  }

  AlertDialog addClientDialog(MySettings settings, int index, {int? clientId}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        index == 2 ? Text(AppLocalizations.of(context).translate("add_client")) : Text(AppLocalizations.of(context).translate("edit")),
          InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.cancel)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(onPressed: (){
                    nameController.clear();
                  }, icon: const Icon(Icons.clear)),
                  isDense: true,
                  fillColor: Colors.grey.shade200,
                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                  labelText: AppLocalizations.of(context).translate("new_account_name"),
                  focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(onPressed: (){
                    phoneController.clear();
                  }, icon: const Icon(Icons.clear)),
                  isDense: true,
                  fillColor: Colors.grey.shade200,
                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                  labelText: AppLocalizations.of(context).translate("new_account_phone"),
                  focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Visibility(
                visible: false,
                child: TextFormField(
                  controller: pswController,
                  autofocus: true,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(onPressed: (){
                      pswController.clear();
                    }, icon: const Icon(Icons.clear)),
                    isDense: true,
                    fillColor: Colors.grey.shade200,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                    labelText: AppLocalizations.of(context).translate("new_account_password"),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(18),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(MediaQuery.of(context).size.width, 50),
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (nameController.text == "") {
                          showRedSnackBar("${AppLocalizations.of(context).translate("profile_name_error")}");
                          return;
                        }
                        if (phoneController.text == "") {
                          showRedSnackBar("${AppLocalizations.of(context).translate("profile_phone_error")}");
                          return;
                        }
                        // if (pswController.text == "") {
                        //   showRedSnackBar("${AppLocalizations.of(context).translate("profile_psw_error")}");
                        //   return;
                        // }

                        if (index == 1 && clientId != null) {
                          await editClient(settings, clientId);
                        } else {
                          await addClient(settings);
                        }

                      }, child: Text(AppLocalizations.of(context).translate("profile_save")))
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }
  void showSuccessSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  Future<void> addClient(MySettings settings) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-add");

    Response? res;
    res = await post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
      body: jsonEncode({
        "name": nameController.text,
        "phone": phoneController.text,
        "psw": "1"
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      getAllClients(settings);
      nameController.clear();
      phoneController.clear();
      pswController.clear();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

  Future<void> editClient(MySettings settings, int id) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-edit");

    Response? res;
    res = await post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
      body: jsonEncode({
        "id": id,
        "name": nameController.text,
        "phone": phoneController.text,
        "psw": pswController.text
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      getAllClients(settings);
      nameController.clear();
      phoneController.clear();
      pswController.clear();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }



  Future<void> generateCode(BuildContext context, MySettings settings, int id) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-qr");

    Response? res;
    res = await post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
      body: jsonEncode({
        "id": id,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["ok"] == 1 && data["d"] != null) {

        String code = data["d"].toString();
        String formattedCode = "${code.substring(0, 3)} ${code.substring(3)}";

        showDialog(context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).translate("code_for_login")),
              actionsPadding: const EdgeInsets.all(12),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(formattedCode, style: const TextStyle(letterSpacing: 5,fontWeight: FontWeight.bold, fontSize: 30)),
                    const SizedBox(width: 10),
                    IconButton(onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_successfully_copied"));
                    }, icon: const Icon(Icons.copy))
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      } else {
        debugPrint("Error: ${res.statusCode}");
        showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
      }
    }
  }
}
