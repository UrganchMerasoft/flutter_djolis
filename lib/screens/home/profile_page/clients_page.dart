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
  bool _shimmer = true;
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate("clients")),
        centerTitle: true,
        actions:[
          IconButton(onPressed: (){
            showDialog(context: context, builder: (BuildContext context) => addClientDialog(settings, 2, ));
          }, icon: const Icon(Icons.add))
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: (){
                      nameController.text = clients[index].name;
                      phoneController.text = clients[index].phone;
                      pswController.text = clients[index].psw;
                      showDialog(context: context, builder: (BuildContext context) => addClientDialog(settings, 1, clientId: clients[index].id));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                      child: Slidable(
                        endActionPane: ActionPane(
                          extentRatio: 0.20,
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              borderRadius: BorderRadius.circular(8),
                              backgroundColor: Colors.green,
                              icon: Icons.password_sharp,
                              label: "Code",
                              onPressed: (BuildContext context1) async {
                                Future.delayed(const Duration(milliseconds: 200), () async {
                                  await generateCode(context,settings, clients[index].id);
                                });
                              },
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(clients[index].name, style: Theme.of(context).textTheme.titleSmall),
                                    // Text(clients[index].psw, style: Theme.of(context).textTheme.titleSmall),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 10),
                                    Text(clients[index].phone, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    

    );
  }
  Future<void> getAllClients(MySettings settings) async {

    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    _isLoading = true;
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
      _isLoading = false;
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
      _isLoading = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      _isLoading = false;
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
          _shimmer = false;
        });

      }
    }
  }

  AlertDialog addClientDialog(MySettings settings, int index, {int? clientId}) {
    return AlertDialog(
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
