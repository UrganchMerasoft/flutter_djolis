import 'dart:convert';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class FirebaseNotificationPage extends StatefulWidget {
  const FirebaseNotificationPage({super.key});
  static const route = '/notificationPage';

  @override
  State<FirebaseNotificationPage> createState() => _FirebaseNotificationPageState();
}

class _FirebaseNotificationPageState extends State<FirebaseNotificationPage> {

  int currentValue = 1;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).translate("warnings")),
        actions: [
          IconButton(onPressed: () {
            setAllRead(settings);
          }, icon: const Icon(Icons.check))
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey.shade300,
          child: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: AnimatedToggleSwitch.size(
                  current: currentValue,
                  values: const [1, 2],
                  iconOpacity: 1,
                  height: 60,
                  indicatorSize: const Size.fromWidth(115),
                  borderWidth: 5,
                  customIconBuilder: (context, local, global) {
                    switch (local.value) {
                      case 1:
                        return Text(AppLocalizations.of(context).translate("push_news"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
                      case 2:
                        return Text(AppLocalizations.of(context).translate("push_notifs"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
                      default:
                        return const Text("");
                    }
                  },
                  style: ToggleStyle(
                    indicatorColor: Theme.of(context).primaryColor,
                    borderColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.transparent,
                  ),
                  selectedIconScale: 1,
                  onChanged: (value) {
                    currentValue = value;
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: DataService.notifs.length,
                    itemBuilder: (context, index) {
                      return Visibility(
                        visible: currentValue == 1 ? DataService.notifs[index].pic_url.isNotEmpty : DataService.notifs[index].pic_url.isEmpty,
                        child: Card(
                          shape: DataService.notifs[index].has_read == false
                              ?  RoundedRectangleBorder(
                              side:  const BorderSide(color: Colors.red, width: 2.0),
                              borderRadius: BorderRadius.circular(4.0))
                              :  RoundedRectangleBorder(
                              side:  const BorderSide(color: Colors.white, width: 2.0),
                              borderRadius: BorderRadius.circular(4.0)),
                          child: InkWell(
                            onTap: () {
                              if (DataService.notifs[index].pic_url.isNotEmpty) {
                                showImageViewer(
                                  context,
                                  Image.network(DataService.notifs[index].pic_url).image,
                                  useSafeArea: true,
                                  backgroundColor: Colors.black,
                                  swipeDismissible: true,
                                  doubleTapZoomable: true,
                                );
                              }
                              setAsReadOnServer(settings, index);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                    visible: DataService.notifs[index].pic_url != "",
                                    child: CachedNetworkImage(
                                      imageUrl: DataService.notifs[index].pic_url,
                                      errorWidget: (context, v, d) {
                                        return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              image: const DecorationImage(image: AssetImage("assets/images/no_image_available.png"),fit: BoxFit.cover),
                                            ));
                                      },
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5, right: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(DataService.notifs[index].msg_title, style: Theme.of(context).textTheme.titleSmall)),
                                        Text(DataService.notifs[index].curtime, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 5, right: 12, top: 10, bottom: 8),
                                    child: Text(DataService.notifs[index].msg, style: Theme.of(context).textTheme.bodyMedium,),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void setAsReadOnServer(MySettings settings, int index) async {
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/set-as-read");

    Response res = await post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "phone": settings.clientPhone,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode(DataService.notifs[index])
    );

    Map? data;
    try {
      data = jsonDecode(res.body);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      return;
    }

    if (data["ok"] == 1) {
      setState(() {
        DataService.notifs[index].has_read = true;
      });
    }
  }

  void setAllRead(MySettings settings) async {
    final action = CupertinoActionSheet(
      message: Text(AppLocalizations.of(context).translate("push_read_all"), style: TextStyle(fontSize: 15.0)),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: () async {
            try {
              for (int i = 0; i < DataService.notifs.length; i++) {
                setAsReadOnServer(settings, i);
              }
            } catch(e) {
            } finally {
              Navigator.pop(context);
            }
          },
          child: Text(AppLocalizations.of(context).translate("gl_yes")),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(AppLocalizations.of(context).translate("gl_no")),
        onPressed: () async {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
