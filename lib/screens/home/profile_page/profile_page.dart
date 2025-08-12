
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/screens/home/orders.dart';
import 'package:flutter_djolis/screens/home/profile_page/bank_cards_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../core/mysettings.dart';
import '../../../services/utils.dart';
import 'clients_page.dart';
import '../my_promo_page.dart';

class ProfilePage extends StatefulWidget {
  final MySettings settings;
  const ProfilePage({super.key, required this.settings});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  TextEditingController paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      DataService.getAllSettings(widget.settings);
      paymentController.text = settings.payInfo;
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
                   Card(child: Padding(
                     padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppLocalizations.of(context).translate("profile_shop_name"), style: Theme.of(context).textTheme.bodySmall),
                         const SizedBox(height: 4),
                         Text(widget.settings.clientId.toString() + " - " + widget.settings.clientName, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                       ],
                     ),
                   ),),
        
                   Card(child: Padding(
                     padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppLocalizations.of(context).translate("profile_address"),style: Theme.of(context).textTheme.bodySmall),
                         const SizedBox(height: 4),
                         Text(widget.settings.clientAddress, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                       ],
                     ),
                   ),),
        
                   Card(child: Padding(
                     padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppLocalizations.of(context).translate("profile_phone"),style: Theme.of(context).textTheme.bodySmall),
                         const SizedBox(height: 4),
                         Text(widget.settings.clientPhone, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                       ],
                     ),
                   ),),
        
                   Card(child: Padding(
                     padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppLocalizations.of(context).translate("profile_fio"),style: Theme.of(context).textTheme.bodySmall),
                         const SizedBox(height: 4),
                         Text(widget.settings.clientFio, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
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
                            Text(AppLocalizations.of(context).translate("profile_base_name"), style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(settings.baseName + " " + settings.basePhone, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),

                   Visibility(
                      visible: settings.clientPhone != "+998977406675",
                      child: const SizedBox(height: 24),
                    ),
                    InkWell(
                     onTap: (){
                       showDialog(context: context, builder: (BuildContext context) => setPayInfo(settings));
                     },
                     child: Visibility(
                       visible: settings.clientPhone != "+998977406675",
                       child: Card(
                         child: Padding(
                           padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.start,
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(AppLocalizations.of(context).translate("client_pay_info"), style: Theme.of(context).textTheme.bodySmall),
                               const SizedBox(height: 5),

                               Row(
                                 mainAxisAlignment: MainAxisAlignment.start,
                                 crossAxisAlignment: CrossAxisAlignment.center,
                                 children: [
                                   const Icon(Icons.people_alt_outlined),
                                   const SizedBox(width: 5),
                                   Expanded(child: Text(settings.payInfo, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
                                   const Icon(Icons.edit_outlined)
                                 ],
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   ),

                    Visibility(
                      visible: settings.clientPhone != "+998977406675" && settings.allowedMijozCount != 0,
                     child: Card(
                         child: InkWell(
                           onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsPage()));
                           },
                           child: Padding(
                             padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.start,
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 const Icon(Icons.people_alt_outlined),
                                 const SizedBox(width: 5),
                                 Expanded(child: Text(AppLocalizations.of(context).translate("clients"), style: Theme.of(context).textTheme.titleSmall)),
                                 const Icon(Icons.chevron_right)
                               ],
                             ),
                           ),
                         )),
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
                   )),
                   Card(color: Colors.yellow, child: InkWell(
                     onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPromo()));
                     },
                     child: Padding(
                       padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.start,
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           const Icon(Icons.card_giftcard),
                           const SizedBox(width: 5),
                           Expanded(child: Text(AppLocalizations.of(context).translate("my_discounts"), style: Theme.of(context).textTheme.titleSmall)),
                           const Icon(Icons.chevron_right)
                         ],
                       ),
                     ),
                   )),
                    Card(
                      color: Colors.blue.shade50,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => OrdersPage()));
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.reorder_sharp),
                              const SizedBox(width: 5),
                              Expanded(child: Text(AppLocalizations.of(context).translate("profile_open_orders"), style: Theme.of(context).textTheme.titleSmall)),
                              const Icon(Icons.chevron_right)
                            ],
                          ),
                        ),
                      ),
                    ),
                   Visibility(
                     visible: settings.clientPhone != "+998977406675",
                     child: Card(
                       child: InkWell(
                         onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const BankCardsPage()));
                         },
                         child: Padding(
                           padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.start,
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               const Icon(Icons.credit_card_sharp),
                               const SizedBox(width: 5),
                               Expanded(child: Text(AppLocalizations.of(context).translate("my_bank_cards"), style: Theme.of(context).textTheme.titleSmall)),
                               const Icon(Icons.chevron_right)
                             ],
                           ),
                         ),
                       ),
                     ),
                   ),

                    Card(
                     child: ExpansionTile(
                         title: Row(
                           children: [
                             const Icon(Icons.share, color: Colors.black,),
                             const SizedBox(width: 5),
                             Text(AppLocalizations.of(context).translate("share_app"), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                           ],
                         ),
                       children: [

                         Visibility(
                           visible: settings.clientPhone != "+998977406675",
                           child: InkWell(
                             onTap: (){
                               showDialog(context: context, builder: (context){
                                 return  AlertDialog(
                                   actions: [
                                     Center(
                                       child: Padding(
                                         padding: const EdgeInsets.only(top: 16),
                                         child: Text("Google Play", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                                       ),
                                     ),
                                     const Image(image: AssetImage("assets/images/qr_google_djolis.jpg"))
                                   ],
                                 );
                               });
                             },
                             child: Container(
                               height: 60,
                               decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(10)
                               ),
                               child: const Image(image: AssetImage("assets/images/google_play.png"), fit: BoxFit.cover,),
                             ),
                           ),
                         ),
                         const SizedBox(height: 15),

                         /// App Store
                         InkWell(
                           onTap: (){
                             showDialog(context: context, builder: (context){
                               return  AlertDialog(
                                 actions: [
                                   Center(
                                     child: Padding(
                                       padding: const EdgeInsets.only(top: 16),
                                       child: Text("App Store", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                                     ),
                                   ),
                                   const Image(image: AssetImage("assets/images/qr_djolis_appstore.jpg"))
                                 ],
                               );
                             });
                           },
                           child: Container(
                             height: 60,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(6),
                             ),
                             child: const Image(image: AssetImage("assets/images/appStore.png"), fit: BoxFit.cover),
                           ),
                         ),
                         const SizedBox(height: 25),
                       ],
                     ),
                   ),

                   OutlinedButton(onPressed: () {
                     showDeleteAccountInfo(settings);
                   }, child: Text(AppLocalizations.of(context).translate("delete_account")))
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

  AlertDialog setPayInfo(MySettings settings) {
    return AlertDialog(
     title: Text(AppLocalizations.of(context).translate("set_pay_info")),
      actions: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: TextFormField(
                      controller: paymentController,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        isDense: true,
                        fillColor: Colors.grey.shade200,
                        errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                        labelText: AppLocalizations.of(context).translate("enter_info"),
                        focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                        border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                        enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
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
                      if (paymentController.text == "") {
                        showRedSnackBar("${AppLocalizations.of(context).translate("gl_cannot_empty")}");
                        return;
                      }
                      await sendPaymentInfo(settings);
                      paymentController.clear();

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

  Future<void> sendPaymentInfo(MySettings settings) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/set-pay-info");

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
        "info": paymentController.text,
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      await DataService.getAllSettings(settings);
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

}
