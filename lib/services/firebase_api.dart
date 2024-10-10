import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../screens/firebase_notifications/firebase_notification_page.dart';
import 'local_notification_service.dart';


Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
  print("Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  late AndroidNotificationChannel channel;
  String? fcmToken;
  final _firebaseMessaging = FirebaseMessaging.instance;

  void handleMessage(RemoteMessage? message) {

    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      FirebaseNotificationPage.route,
      arguments: message,
    );
  }

  Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handleMessage(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    channel = const AndroidNotificationChannel('high_importance_channel', 'High Importance Notifications', description: 'This channel is used for important notifications.', importance: Importance.max);
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
         LocalNotificationService().display(message);
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: "@mipmap/ic_launcher",
                  // largeIcon: ByteArrayAndroidBitmap.fromBase64String(await networkImageToBase64(message.data["userPhoto"]))
                ),
              ));
        }

        if (Platform.isIOS) {
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            RemoteNotification? notification = message.notification;

            if (notification != null) {
              // print("AAA");
              flutterLocalNotificationsPlugin.show(
                  notification.hashCode,
                  notification.title,
                  notification.body,
                  const NotificationDetails(iOS: DarwinNotificationDetails()));
            }
          });
        }
      });
    }

    if (Platform.isIOS) {
      // _firebaseMessaging.getAPNSToken().then((f) => print(f)).catchError((v) => print(v));
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      print("APNS Token: $apnsToken");
      if (apnsToken == null) {
        print('APNS token not available');
        return;
      }
    } else {
      fcmToken = await _firebaseMessaging.getToken();
      print("FCM Token: $fcmToken");
    }

    await initPushNotifications();
  }
}