import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_djolis/screens/account/login_page.dart';
import 'package:flutter_djolis/screens/firebase_notifications/firebase_notification_page.dart';
import 'package:flutter_djolis/screens/home/home.dart';
import 'package:flutter_djolis/services/firebase_api.dart';
import 'package:flutter_djolis/services/local_notification_service.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:flutter_djolis/wrapper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'core/mysettings.dart';
import 'firebase_options.dart';


final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  LocalNotificationService.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MySettings>(create: (_) => MySettings(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    setInitialData(settings);
    ThemeData themeDataLight = FlexThemeData.light(scheme: FlexScheme.custom, colorScheme: const ColorScheme.light(primary: Color.fromRGBO(120, 46, 76, 1)), fontFamily: "Inter");
    ThemeData themeDataDark = FlexThemeData.dark(scheme: FlexScheme.custom, colorScheme: const ColorScheme.dark(brightness: Brightness.dark, primary: Color.fromRGBO(124, 46, 76, 1)), fontFamily: "Inter");

    ThemeData themeLight = themeDataLight.copyWith(textTheme: themeDataLight.textTheme.copyWith(
      displayLarge: themeDataLight.textTheme.displayLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      displayMedium: themeDataLight.textTheme.displayMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      displaySmall: themeDataLight.textTheme.displaySmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodyLarge: themeDataLight.textTheme.bodyLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodyMedium: themeDataLight.textTheme.bodyMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodySmall: themeDataLight.textTheme.bodySmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleLarge: themeDataLight.textTheme.titleLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleMedium: themeDataLight.textTheme.titleMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleSmall: themeDataLight.textTheme.titleSmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelLarge: themeDataLight.textTheme.labelLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelMedium: themeDataLight.textTheme.labelMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelSmall: themeDataLight.textTheme.labelSmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
    ));

    ThemeData themeDark = themeDataDark.copyWith(textTheme: themeDataDark.textTheme.copyWith(
      displayLarge: themeDataDark.textTheme.displayLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      displayMedium: themeDataDark.textTheme.displayMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      displaySmall: themeDataDark.textTheme.displaySmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodyLarge: themeDataDark.textTheme.bodyLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodyMedium: themeDataDark.textTheme.bodyMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      bodySmall: themeDataDark.textTheme.bodySmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleLarge: themeDataDark.textTheme.titleLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleMedium: themeDataDark.textTheme.titleMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      titleSmall: themeDataDark.textTheme.titleSmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelLarge: themeDataDark.textTheme.labelLarge!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelMedium: themeDataDark.textTheme.labelMedium!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
      labelSmall: themeDataDark.textTheme.labelSmall!.copyWith(letterSpacing: -0.2, fontFamily: "Inter"),
    ));

    return MaterialApp(

      theme: themeLight,
      darkTheme: themeDark,
      themeMode: ThemeMode.light,
      // themeMode: settings.theme == MySettings.THEME_AUTO ? ThemeMode.system : (settings.theme == MySettings.THEME_LIGHT ? ThemeMode.light : ThemeMode.dark),
      title: "Djolis",
      locale: settings.locale,
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale("uz", "UZ"),
        Locale("ru", "RU"),
        Locale("en", "US"),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale!.languageCode && supportedLocale.countryCode == locale.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      navigatorKey: navigatorKey,
      home: settings.token.isEmpty ? const LoginPage() : const HomePage(),

      routes: {
        FirebaseNotificationPage.route: (context) => const FirebaseNotificationPage(),
      },
    );
  }

  void setInitialData(MySettings settings) async {
    Utils.numFormatCurrent = Utils.numFormat0;

    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // MySettings.syncVersion = Utils.checkDouble("0${packageInfo.buildNumber}").toInt();
    // MySettings.version = "${packageInfo.version}.${packageInfo.buildNumber}";

    Permission.storage.shouldShowRequestRationale;
  }
}