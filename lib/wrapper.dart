// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_djolis/screens/account/login_page.dart';
// import 'package:flutter_djolis/screens/home/home.dart';
// import 'package:provider/provider.dart';
// import 'core/db.dart';
// import 'core/mysettings.dart';
//
// class Wrapper extends StatelessWidget {
//   const Wrapper({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<MySettings>(context);
//     // if (settings.mainDbId == 0) {
//     //   return const LoginPage();
//     // }
//     // settings.fireUser = "common_user";
//
//     if (settings.token.isEmpty) {
//       return const LoginPage();
//     } else {
//       return const HomePage();
//     }
//   }
//
//   Widget progressPage(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SpinKitCircle(
//               color: Theme.of(context).primaryColor,
//               size: 60.0),
//         ),
//       ),
//     );
//   }
//
// }
