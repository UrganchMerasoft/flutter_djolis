
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/screens/home/orders.dart';
import 'package:flutter_djolis/screens/mijoz_screens/mijoz_location_map.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../core/mysettings.dart';
import '../../services/utils.dart';

class MijozProfilePage extends StatefulWidget {
  final MySettings settings;
  const MijozProfilePage({super.key, required this.settings});

  @override
  State<MijozProfilePage> createState() => _MijozProfilePageState();
}

class _MijozProfilePageState extends State<MijozProfilePage> {

  TextEditingController addressController = TextEditingController();
  TextEditingController coordinateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      DataService.getAllSettings(widget.settings);
      addressController.text = settings.mijozAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    DataService.getAllSettings(settings);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey.shade200,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12 , right: 12, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: settings.clientPhone,
                        );
                        await launchUrl(launchUri);
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("cosmetolog_phone"), style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: Text(settings.clientPhone, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                  const Icon(Icons.phone),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).translate("mijoz_name"),style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(settings.mijozName, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).translate("mijoz_phone"), style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(settings.mijozPhone, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: (){
                        addressController.text = settings.mijozAddress;
                        showDialog(context: context, builder: (BuildContext context) => setMijozAddress(settings));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("mijoz_address"), style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 5),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.map),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(settings.mijozAddress, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
                                  const Icon(Icons.edit_outlined)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: InkWell(
                        onTap: () async{
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_history),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(AppLocalizations.of(context).translate("set_location_with_map"), style: Theme.of(context).textTheme.titleSmall)),
                                  const Icon(Icons.chevron_right)
                                ],
                              ),
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(left: 30),
                                child: Text("${settings.mijozGpsLng}, ${settings.mijozGpsLat}", style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w800)),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                        child: InkWell(
                          onTap: () {
                            selectLang(context, settings);
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.translate),
                                const SizedBox(width: 5),
                                Expanded(child: Text(AppLocalizations.of(context).translate("language"), style: Theme.of(context).textTheme.titleSmall)),
                                const Icon(Icons.chevron_right)
                              ],
                            ),
                          ),
                        ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 16, 5, 16),
                      child: OutlinedButton(onPressed: () {
                        showDeleteAccountInfo(settings);
                      }, child: Text(AppLocalizations.of(context).translate("delete_account"))),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
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

          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 3;
              settings.locale = const Locale("ar", "AR");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("arabic"),
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
                ListTile(
                  leading: Text(
                    "🇦🇪",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title:
                  Text(AppLocalizations.of(context).translate("arabic")),
                  onTap: () {
                    settings.language = 3;
                    settings.locale = const Locale("ar", "AR");
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

  void showDeleteAccountInfo(MySettings settings) {
    Dialog errorDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
      child: Container(
        height: 270.0,
        width: 26.0,
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(AppLocalizations.of(context).translate("delete_account_info"), style: Theme.of(context).textTheme.titleMedium,),
              const SizedBox(height: 12),
              Text("+971 55 262 0505", style: Theme.of(context).textTheme.titleSmall,),
              const  SizedBox(height: 8),
              Text("djolis@djolis.com", style: Theme.of(context).textTheme.titleSmall,),
              const SizedBox(height: 24),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.purple, fontSize: 18.0),))
            ],
          ),
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => errorDialog);
  }

  AlertDialog setMijozAddress(MySettings settings) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate("profile_address")),
      actions: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 15, 10),
              child: SizedBox(
                height: 100,
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.top,
                  expands: true,
                  controller: addressController,
                  autofocus: true,
                  minLines: null,
                  maxLines: null,
                  decoration: InputDecoration(
                    isDense: false,
                    fillColor: Colors.grey.shade200,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                    labelText: AppLocalizations.of(context).translate("enter_address"),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  ),
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
                      if (addressController.text == "") {
                        showRedSnackBar(AppLocalizations.of(context).translate("gl_cannot_empty"));
                        return;
                      }
                      await sendMijozAddress(settings);
                      addressController.clear();

                    }, child: Text(AppLocalizations.of(context).translate("profile_save")))
            ),
          ],
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

  Future<void> sendMijozAddress(MySettings settings) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-update");

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
        "id": settings.mijozId,
        "address": addressController.text,
        "gps_lat": settings.mijozGpsLat,
        "gps_lng": settings.mijozGpsLng
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      await DataService.getAllSettings(settings);
      settings.mijozAddress = addressController.text;
      settings.saveAndNotify();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

}
