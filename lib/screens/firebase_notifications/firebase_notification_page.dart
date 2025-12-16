import 'dart:convert';
import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:flutter_djolis/screens/firebase_notifications/video_notifs_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../services/utils.dart';

class FirebaseNotificationPage extends StatefulWidget {
  const FirebaseNotificationPage({super.key});
  static const route = '/notificationPage';

  @override
  State<FirebaseNotificationPage> createState() => _FirebaseNotificationPageState();
}

class _FirebaseNotificationPageState extends State<FirebaseNotificationPage> {
  int currentValue = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    getAll(settings);
    return Container(
      decoration:  const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/back_wallpaper.png"),fit: BoxFit.fill)
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          return await getAll(settings);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context).translate("warnings"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: IconButton(
                      onPressed: () {
                        setAllRead(settings);
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Glassmorphic Toggle Switch
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.2,
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
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: AnimatedToggleSwitch.size(
                          current: currentValue,
                          values: const [1, 2],
                          iconOpacity: 1,
                          height: 60,
                          indicatorSize: const Size.fromWidth(115),
                          borderWidth: 0,
                          customIconBuilder: (context, local, global) {
                            switch (local.value) {
                              case 1:
                                return Text(
                                  AppLocalizations.of(context).translate("push_news"),
                                  style: TextStyle(
                                    color: Color.lerp(Colors.white70, Colors.white, local.animationValue),
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              case 2:
                                return Text(
                                  AppLocalizations.of(context).translate("push_notifs"),
                                  style: TextStyle(
                                    color: Color.lerp(Colors.white70, Colors.white, local.animationValue),
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
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
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notifications List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: DataService.notifs.length,
                      itemBuilder: (context, index) {
                        return Visibility(
                          visible: currentValue == 1
                              ? DataService.notifs[index].pic_url.isNotEmpty
                              : DataService.notifs[index].pic_url.isEmpty,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withOpacity(0.45),
                                border: Border.all(
                                  color: DataService.notifs[index].has_read == false
                                      ? Colors.red.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.4),
                                  width: DataService.notifs[index].has_read == false ? 2 : 1.2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      if (DataService.notifs[index].video_url.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReelsView(DataService.notifs[index].video_url),
                                          ),
                                        );
                                        setAsReadOnServer(settings, index);
                                        return;
                                      }
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Image/Video Section
                                          if (DataService.notifs[index].pic_url.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CachedNetworkImage(
                                                    imageUrl: DataService.notifs[index].pic_url,
                                                    errorWidget: (context, v, d) {
                                                      return Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(12),
                                                          image: const DecorationImage(
                                                            image: AssetImage("assets/images/no_image_available.png"),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    fit: BoxFit.cover,
                                                  ),
                                                  if (DataService.notifs[index].video_url.isNotEmpty)
                                                    Container(
                                                      height: 220,
                                                      width: 150,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(12),
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.black.withOpacity(0.3),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => ReelsView(DataService.notifs[index].video_url),
                                                            ),
                                                          );
                                                        },
                                                        icon: Icon(
                                                          CupertinoIcons.play_circle_fill,
                                                          size: 80,
                                                          color: Colors.white.withOpacity(0.9),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          if (DataService.notifs[index].pic_url.isNotEmpty)
                                            const SizedBox(height: 12),
                                          // Title and Time
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  DataService.notifs[index].msg_title,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    color: Theme.of(context).primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.black12,
                                                ),
                                                child: Text(
                                                  DataService.notifs[index].curtime,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 11,

                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Message
                                          Text(
                                            DataService.notifs[index].msg,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.black87,
                                              height: 1.4,
                                            ),
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
      ),
    );
  }

  Future<void> getAll(MySettings settings) async {
    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/getall");
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
        print("Error data null or data['ok] != 1");
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
      return;
    }

    if (data == null || data["ok"] != 1) {
      _isLoading = false;
      if (kDebugMode) {
        debugPrint("Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      DataService.notifs = (data['d']["notifs"] as List?)?.map((item) => NotifModel.fromMapObject(item)).toList() ?? [];
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      body: jsonEncode(DataService.notifs[index]),
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
      message: Text(
        AppLocalizations.of(context).translate("push_read_all"),
        style: const TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: () async {
            try {
              for (int i = 0; i < DataService.notifs.length; i++) {
                setAsReadOnServer(settings, i);
              }
            } catch (e) {
              debugPrint(e.toString());
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