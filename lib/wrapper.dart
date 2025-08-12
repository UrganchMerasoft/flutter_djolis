import 'package:flutter/material.dart';
import 'package:flutter_djolis/screens/mijoz_screens/mijoz_home_page.dart';
import 'package:flutter_djolis/screens/account/login_page.dart';
import 'package:flutter_djolis/screens/home/home.dart';
import 'package:provider/provider.dart';
import 'core/mysettings.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    if (settings.token.isEmpty) {
      return const LoginPage();
    } else {
      return MySettings.mijozMode
          ? const MijozHomePage()
          : const HomePage();
    }
  }
}

