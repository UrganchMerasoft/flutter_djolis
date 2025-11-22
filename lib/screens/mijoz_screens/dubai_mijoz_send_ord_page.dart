//
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_djolis/models/payed_order_model.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/http.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../../app_localizations.dart';
// import '../../core/mysettings.dart';
// import '../../models/new_payme_model.dart';
// import '../../services/utils.dart';
//
// class DubaiMijozSendOrdPage extends StatefulWidget {
//   const DubaiMijozSendOrdPage({super.key});
//
//   @override
//   State<DubaiMijozSendOrdPage> createState() => _DubaiMijozSendOrdPageState();
// }
//
// class _DubaiMijozSendOrdPageState extends State<DubaiMijozSendOrdPage> {
//   TextEditingController networkController = TextEditingController();
//   TextEditingController commentController = TextEditingController();
//
//   List<NewPaymeModel> paymeList = [];
//   List<PayedOrderModel> payedOrders = [];
//   double totalSumm = 0;
//   bool isSending = false;
//   File? selectedImage1;
//   File? selectedImage2;
//   String networkUrl = "";
//   String urnOrderId = "";
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final settings = Provider.of<MySettings>(context, listen: false);
//       networkController.text = settings.itogSumm.toString();
//     });
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<MySettings>(context);
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Text(AppLocalizations.of(context).translate("verify_ord")),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(AppLocalizations.of(context).translate("akt_sverka_pay"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
//               const SizedBox(height: 10),
//               Center(
//                 child: Card(
//                   elevation: 10,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   child: InkWell(
//                       onTap: () {
//                         networkPayDialog(context, settings);
//                       },
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.all(Radius.circular(10)),
//                         ),
//                         child: const Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Center(child: Image(image: AssetImage("assets/images/logo-network.png"), height: 100,)),
//                           ],
//                         ),
//                       )
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
//                 child: TextFormField(
//                   controller: commentController,
//                   decoration: InputDecoration(
//                     isDense: true,
//                     fillColor: Colors.white,
//                     errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(14)),
//                     labelText: AppLocalizations.of(context).translate("akt_sverka_notes"),
//                     focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
//                     focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
//                     border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
//                     enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.orange.shade500),
//                   const SizedBox(width: 5),
//                   Expanded(child: Text(AppLocalizations.of(context).translate("notes_warning"), style: TextStyle(color: Colors.orange.shade500, fontSize: 12))),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(8),
//           child: Container(
//             decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(20)),
//             height: 140,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 25, 20, 16),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(left: 4),
//                         child: Text(AppLocalizations.of(context).translate("gl_summa_ord"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
//                       ),
//                       Text(Utils.numFormat0.format(settings.itogSumm), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
//                     ],
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           flex: 4,
//                           child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 fixedSize: Size(MediaQuery.of(context).size.width, 45),
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                               ),
//                               onPressed: () {
//                                 Navigator.pop(context);
//                               },
//                               child: Text(AppLocalizations.of(context).translate("gl_back"), style: TextStyle(color: Theme.of(context).primaryColor))),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           flex: 6,
//                           child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 fixedSize: Size(MediaQuery.of(context).size.width, 45),
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                               ),
//
//                               onPressed: () {
//                                 sendOrder(settings);
//                               },
//                               child: Text(AppLocalizations.of(context).translate("gl_send"), style: TextStyle(color: Theme.of(context).primaryColor))),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void showRedSnackBar(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
//   }
//
//   void showSuccessSnackBar(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
//   }
//
//
//   void sendOrder(MySettings settings) async {
//     try {
//       final uri = Uri.parse("${settings.serverUrl}/api-djolis/send-mijoz-order");
//
//       final response = await http.post(
//         uri,
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           "lang": settings.locale.languageCode,
//           "phone": settings.clientPhone,
//           "Authorization": "Bearer ${settings.token}",
//         },
//         body: jsonEncode({
//           "notes": commentController.text,
//           "clientId": settings.clientId,
//           "itogSumm": settings.itogSumm,
//           "myUuid": "",
//           "list": settings.cartList,
//         }),
//       );
//
//       print("RESPONSE: ${response.body}");
//
//       if (!context.mounted) return;
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data["ok"] == 1) {
//           settings.cartList.clear();
//           settings.vitrinaList.clear();
//           settings.saveAndNotify();
//           showSuccessSnackBar(AppLocalizations.of(context).translate("sent_ord"));
//           Navigator.pop(context);
//         } else {
//           showRedSnackBar(AppLocalizations.of(context).translate("error"));
//         }
//       } else {
//         showRedSnackBar("${AppLocalizations.of(context).translate("server_error_code")} ${response.statusCode}");
//       }
//     } catch (e) {
//       if (context.mounted) {
//         showRedSnackBar("Error: $e");
//       }
//     } finally {
//       if (mounted) {
//         setState(() => isSending = false);
//       }
//     }
//   }
//
//   void networkPayDialog(BuildContext context, MySettings settings) => showDialog(context: context, builder: (BuildContext context) => AlertDialog(
//     titlePadding: EdgeInsets.zero,
//     title: Stack(
//       alignment: Alignment.topRight,
//       children: [
//         const Center(child: Image(image: AssetImage("assets/images/logo-network.png"), width: 250)),
//         IconButton(onPressed: (){
//           Navigator.pop(context);
//         }, icon: const Icon(Icons.cancel)),
//         const SizedBox(width: 20),
//       ],
//     ),
//     actions: [
//       Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 8,
//                   child: TextFormField(
//                     controller: networkController,
//                     keyboardType: const TextInputType.numberWithOptions(),
//                     autofocus: true,
//                     decoration: InputDecoration(
//                       isDense: true,
//                       fillColor: Colors.grey.shade200,
//                       errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
//                       labelText: AppLocalizations.of(context).translate("enter_summ"),
//                       focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
//                       focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
//                       border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
//                       enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   flex: 2,
//                   child: InkWell(
//                     onTap: ()async{
//                       if(networkController.text.isEmpty){
//                         showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
//                       }else if(double.parse(networkController.text) <= 50){
//                         showRedSnackBar(AppLocalizations.of(context).translate("enter_more_summ"));
//                       } else{
//                         await networkPayment(settings);
//                         await Share.share("network link: $networkUrl");
//                       }
//                     },
//                     child: Container(
//                       height: 52,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.grey.shade500),
//                         color: Colors.grey.shade200,
//                       ),
//                       child: const Icon(Icons.share_outlined),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//               padding: const EdgeInsets.all(15),
//               child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       fixedSize: Size(MediaQuery.of(context).size.width, 50),
//                       backgroundColor: const Color.fromRGBO(40, 105, 172, 1),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
//                   onPressed: () async {
//                     if (isSending) {
//                       return;
//                     }
//                     Navigator.pop(context);
//                     setState(() {
//                       isSending = true;
//                     });
//                     if (networkController.text.isEmpty) {
//                       showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
//                       isSending = false;
//                     } else {
//                       await networkPayment(settings);
//                       launchUrl(Uri.parse(networkUrl), mode: LaunchMode.externalApplication);
//                       isSending = false;
//                       networkController.clear();
//                     }
//                   },
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const SizedBox(width: 10),
//                       Text(AppLocalizations.of(context).translate("dash_do_pay")),
//                       const Icon(Icons.chevron_right),
//                     ],
//                   ))),
//         ],
//       ),
//     ],
//   ));
//
//   Future<void> networkPayment(MySettings settings) async {
//     String fcmToken = await Utils.getToken();
//     String device_name = (await Utils.getDeviceName()) ?? "";
//     debugPrint(settings.serverUrl);
//
//     Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius");
//     Response? res;
//     try {
//       res = await post(
//         uri,
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           "lang": settings.locale.languageCode,
//           "fcm_token": fcmToken,
//           "phone": settings.clientPhone,
//           "device_name": device_name,
//           "Authorization": "Bearer ${settings.token}",
//         },
//         body: jsonEncode({
//           "client_id": settings.clientId,
//           "summ": Utils.checkDouble(networkController.text),
//         }),
//       );
//       print("settings.clientId: ${settings.clientId}");
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint("Network error: $e");
//       }
//       return;
//     }
//
//     if (res.body.toString().contains("Invalid Token...")) {
//       settings.logout();
//       return;
//     }
//
//     Map? data;
//     try {
//       data = jsonDecode(res.body);
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error parsing JSON mijoz_send_ord")));
//       }
//       return;
//     }
//
//     print("DATA: ${data}");
//     if (data == null || data["ok"] != 1) {
//       if (kDebugMode) {
//         debugPrint("Response error: data null or data['ok'] != 1");
//       }
//       return;
//     }
//
//     if (data["ok"] == 1) {
//       networkUrl = data['d']['_links']['payment']['href'];
//       urnOrderId = extractOrderId(data['d']['_id']);
//       debugPrint("urnOrderId $urnOrderId");
//     }
//   }
//
//   Future<void> paymentChecker(MySettings settings) async {
//     String fcmToken = await Utils.getToken();
//     String device_name = (await Utils.getDeviceName()) ?? "";
//     debugPrint(settings.serverUrl);
//
//     Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius-check");
//     Response? res;
//     try {
//       res = await post(
//         uri,
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           "lang": settings.locale.languageCode,
//           "fcm_token": fcmToken,
//           "phone": settings.clientPhone,
//           "device_name": device_name,
//           "Authorization": "Bearer ${settings.token}",
//         },
//         body: jsonEncode({
//           "id": urnOrderId,
//         }),
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint("Network error: $e");
//       }
//       return;
//     }
//
//     if (res.body.toString().contains("Invalid Token...")) {
//       settings.logout();
//       return;
//     }
//
//     Map? data;
//     try {
//       data = jsonDecode(res.body);
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error parsing JSON mijoz payment checker")));
//       }
//       return;
//     }
//
//     if (data == null || data["ok"] != 1) {
//       if (kDebugMode) {
//         debugPrint("Response error: data null or data['ok'] != 1");
//       }
//       return;
//     }
//
//     if (data["ok"] == 1) {
//       networkUrl = data['d']['_links']['payment']['href'];
//       urnOrderId = extractOrderId(data['d']['_id']);
//       debugPrint("urnOrderId $urnOrderId");
//       debugPrint("networkUrl $networkUrl");
//     }
//   }
//
//   String extractOrderId(String input) {
//     const prefix = "urn:order:";
//     if (input.startsWith(prefix)) {
//       return input.substring(prefix.length);
//     }
//     return input;
//   }
//
//
// }

import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Timer uchun

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/models/payed_order_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/new_payme_model.dart';
import '../../services/utils.dart';

class DubaiMijozSendOrdPage extends StatefulWidget {
  const DubaiMijozSendOrdPage({super.key});

  @override
  State<DubaiMijozSendOrdPage> createState() => _DubaiMijozSendOrdPageState();
}

class _DubaiMijozSendOrdPageState extends State<DubaiMijozSendOrdPage> with WidgetsBindingObserver {
  TextEditingController networkController = TextEditingController();
  TextEditingController commentController = TextEditingController();

  List<NewPaymeModel> paymeList = [];
  List<PayedOrderModel> payedOrders = [];
  double totalSumm = 0;
  bool isSending = false;
  File? selectedImage1;
  File? selectedImage2;
  String networkUrl = "";
  String urnOrderId = "";

  // To'lov statusini tekshirish uchun
  bool _paymentInProgress = false;
  bool _paymentCompleted = false; // To'lov muvaffaqiyatli yakunlanganini tekshirish
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      networkController.text = settings.itogSumm.toString();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // App lifecycle o'zgarishini kuzatish
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentInProgress && urnOrderId.isNotEmpty) {
      // Foydalanuvchi ilovaga qaytdi, to'lov statusini tekshir
      _checkPaymentStatusAndHandle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context).translate("verify_ord")),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).translate("akt_sverka_pay"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
              const SizedBox(height: 10),
              Center(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                      onTap: () {
                        networkPayDialog(context, settings);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(child: Image(image: AssetImage("assets/images/logo-network.png"), height: 100,)),
                          ],
                        ),
                      )
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // To'lov holati haqida ma'lumot ko'rsatish
              if (_paymentInProgress)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate("payment_status_checking"),
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // To'lov muvaffaqiyatli bo'lganda
              if (_paymentCompleted)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate("payment_successful_order_ready"),
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // To'lov talab qilinadi
              if (!_paymentCompleted && !_paymentInProgress && urnOrderId.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate("payment_required_before_order"),
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: TextFormField(
                  controller: commentController,
                  decoration: InputDecoration(
                    isDense: true,
                    fillColor: Colors.white,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(14)),
                    labelText: AppLocalizations.of(context).translate("akt_sverka_notes"),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade500),
                  const SizedBox(width: 5),
                  Expanded(child: Text(AppLocalizations.of(context).translate("notes_warning"), style: TextStyle(color: Colors.orange.shade500, fontSize: 12))),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(20)),
            height: 140,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(AppLocalizations.of(context).translate("gl_summa_ord"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                      Text(Utils.numFormat0.format(settings.itogSumm), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                fixedSize: Size(MediaQuery.of(context).size.width, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context).translate("gl_back"), style: TextStyle(color: Theme.of(context).primaryColor))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _paymentCompleted ? Colors.white : Colors.grey.shade400,
                                fixedSize: Size(MediaQuery.of(context).size.width, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: (_paymentInProgress || !_paymentCompleted) ? null : () {
                                sendOrder(settings);
                              },
                              child: Text(
                                  AppLocalizations.of(context).translate("gl_send"),
                                  style: TextStyle(
                                      color: _paymentCompleted ? Theme.of(context).primaryColor : Colors.grey.shade600
                                  )
                              )),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  void sendOrder(MySettings settings) async {
    // To'lov tekshiruvi
    if (!_paymentCompleted) {
      showRedSnackBar(AppLocalizations.of(context).translate("payment_required_before_order_exc"));
      return;
    }

    try {
      setState(() => isSending = true);

      final uri = Uri.parse("${settings.serverUrl}/api-djolis/send-mijoz-order");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "phone": settings.clientPhone,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "notes": commentController.text,
          "clientId": settings.clientId,
          "mijoz_id": settings.mijozId,
          "itogSumm": settings.itogSumm,
          "myUuid": "",
          "list": settings.cartList,
        }),
      );

      print("RESPONSE: ${response.body}");

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == 1) {
          settings.cartList.clear();
          settings.vitrinaList.clear();
          settings.saveAndNotify();

          // To'lov holatini reset qilish
          setState(() {
            _paymentCompleted = false;
            urnOrderId = "";
          });

          showSuccessSnackBar(AppLocalizations.of(context).translate("order_sent_successfully"));
          Navigator.pop(context);
        } else {
          showRedSnackBar(AppLocalizations.of(context).translate("error"));
        }
      } else {
        showRedSnackBar("${AppLocalizations.of(context).translate("server_error_code")} ${response.statusCode}");
      }
    } catch (e) {
      if (context.mounted) {
        showRedSnackBar("Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  void networkPayDialog(BuildContext context, MySettings settings) => showDialog(context: context, builder: (BuildContext context) => AlertDialog(
    titlePadding: EdgeInsets.zero,
    title: Stack(
      alignment: Alignment.topRight,
      children: [
        const Center(child: Image(image: AssetImage("assets/images/logo-network.png"), width: 250)),
        IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.cancel)),
        const SizedBox(width: 20),
      ],
    ),
    actions: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: TextFormField(
                    // enabled: false,
                    controller: networkController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    autofocus: false,
                    readOnly: true,
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("dash_pay"),
                      focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                      enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: ()async{
                      if(networkController.text.isEmpty){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      }else if(double.parse(networkController.text) <= 50){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_more_summ"));
                      } else{
                        await networkPayment(settings);
                        await Share.share("network link: $networkUrl");
                      }
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade500),
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(Icons.share_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width, 50),
                      backgroundColor: const Color.fromRGBO(40, 105, 172, 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (isSending) {
                      return;
                    }
                    Navigator.pop(context);
                    setState(() {
                      isSending = true;
                    });
                    if (networkController.text.isEmpty) {
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      setState(() => isSending = false);
                    } else {
                      await networkPayment(settings);
                      if (networkUrl.isNotEmpty) {
                        // To'lov jarayonini boshlash
                        _startPaymentProcess();
                        launchUrl(Uri.parse(networkUrl), mode: LaunchMode.externalApplication);
                      }
                      setState(() => isSending = false);
                      networkController.clear();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context).translate("dash_do_pay")),
                      const Icon(Icons.chevron_right),
                    ],
                  ))),
        ],
      ),
    ],
  ));

  // To'lov jarayonini boshlash
  void _startPaymentProcess() {
    setState(() {
      _paymentInProgress = true;
    });

    // Periodic checking boshlash (har 10 soniyada)
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (urnOrderId.isNotEmpty) {
        _checkPaymentStatusAndHandle();
      }
    });
  }

  // To'lov statusini tekshirish va natijaga qarab harakat qilish
  Future<void> _checkPaymentStatusAndHandle() async {
    final settings = Provider.of<MySettings>(context, listen: false);
    final status = await _checkPaymentStatus(settings);

    switch (status) {
      case 'CAPTURED':
      case 'SUCCESS':
      case 'COMPLETED':
      // To'lov muvaffaqiyatli
        _stopPaymentProcess();
        setState(() {
          _paymentCompleted = true;
        });
        _showPaymentSuccessDialog();
        break;

      case 'FAILED':
      case 'CANCELLED':
      case 'DECLINED':
      case 'EXPIRED':
      // To'lov muvaffaqiyatsiz
        _stopPaymentProcess();
        setState(() {
          _paymentCompleted = false;
        });
        _showPaymentFailure();
        break;

      case 'STARTED':
      case 'AWAIT_3DS':
      case 'PENDING':
      case 'PROCESSING':
      // Hali ham kutish holatida
        break;

      default:
      // Noma'lum holat
        break;
    }
  }

  // To'lov statusini tekshirish
  Future<String> _checkPaymentStatus(MySettings settings) async {
    if (urnOrderId.isEmpty) return 'UNKNOWN';

    try {
      String fcmToken = await Utils.getToken();
      String device_name = (await Utils.getDeviceName()) ?? "";

      Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius-check");

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": device_name,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "id": urnOrderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == 1 && data["d"] != null) {
          // Payment ma'lumotlarini tekshirish
          final embedded = data["d"]["_embedded"];
          if (embedded != null && embedded["payment"] != null && embedded["payment"].isNotEmpty) {
            final paymentState = embedded["payment"][0]["state"];
            return paymentState ?? 'UNKNOWN';
          }
        }
      }
    } catch (e) {
      debugPrint("Payment status check error: $e");
    }

    return 'UNKNOWN';
  }

  // To'lov jarayonini to'xtatish
  void _stopPaymentProcess() {
    setState(() {
      _paymentInProgress = false;
    });
    _statusCheckTimer?.cancel();
  }

  // To'lov muvaffaqiyatli dialog (avtomatik yubormasdan)
  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).translate("payment_successful_title")),
          ],
        ),
        content: Text(AppLocalizations.of(context).translate("payment_successful_message")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // To'lov muvaffaqiyatsizligi haqida xabar
  void _showPaymentFailure() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context).translate("payment_failed_title")),
          ],
        ),
        content: Text(AppLocalizations.of(context).translate("payment_failed_message")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> networkPayment(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";
    debugPrint(settings.serverUrl);

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius");
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
        body: jsonEncode({
          "client_id": settings.clientId,
          "mijoz_id": settings.mijozId,
          "summ": Utils.checkDouble(networkController.text),
        }),
      );
      print("settings.clientId: ${settings.clientId}");
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Network error: $e");
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error parsing JSON mijoz_send_ord")));
      }
      return;
    }

    print("DATA: ${data}");
    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        debugPrint("Response error: data null or data['ok'] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      networkUrl = data['d']['_links']['payment']['href'];
      urnOrderId = extractOrderId(data['d']['_id']);
      debugPrint("urnOrderId $urnOrderId");
    }
  }

  String extractOrderId(String input) {
    const prefix = "urn:order:";
    if (input.startsWith(prefix)) {
      return input.substring(prefix.length);
    }
    return input;
  }
}