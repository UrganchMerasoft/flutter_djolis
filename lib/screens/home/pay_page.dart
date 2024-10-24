import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/screens/home/pay_qr.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/utils.dart';

class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

// ❌❌❌❌❌ Бу page ишлатилмиди, Феруз акада vitrina_page ишлатилад
class _PayPageState extends State<PayPage> {

  bool _shimmer = true;
  bool _isLoading = false;


@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAll(settings);
    });
  }
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

            const SizedBox(height: 12,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.green.shade200,
                  borderRadius: const BorderRadius.all(Radius.circular(8))
              ),
              padding: const EdgeInsets.all(12), child: Text(AppLocalizations.of(context).translate("pay_page_cards"), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium,)),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DataService.cards.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: const BorderRadius.all(Radius.circular(8))
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("pay_page_card_number"), style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4,),
                              Text(DataService.cards[index].card_num, style: Theme.of(context).textTheme.titleSmall,),
                              const SizedBox(height: 8,),
                              Text(AppLocalizations.of(context).translate("pay_page_card_holder"), style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4,),
                              Text(DataService.cards[index].name, style: Theme.of(context).textTheme.titleSmall,),
                              const SizedBox(height: 12,),],)),

                          IconButton(onPressed: () {
                            Clipboard.setData(ClipboardData(text: DataService.cards[index].card_num));
                          }, icon: const Icon(Icons.copy, color: Colors.grey,)),
                        ],
                      ),
                      /// Click, Payme, Uzum
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 45, width: 4),
                          Visibility(
                            visible: DataService.cards[index].payme_url.isNotEmpty,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PayQRPage("PAYME", DataService.cards[index].payme_url, DataService.cards[index])));
                                //launchUrl(Uri.parse(DataService.cards[index].payme_url));
                              },
                              child: Container(
                                height: 40,
                                width: 70,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  image: DecorationImage(image: AssetImage("assets/images/img.png"),fit: BoxFit.fill)
                                ),
                              ),
                            ),
                          ),
                          Visibility(visible: DataService.cards[index].payme_url.isNotEmpty, child: const SizedBox(width: 8,)),
                          Visibility(
                            visible: DataService.cards[index].click_url.isNotEmpty,
                              child: InkWell(
                              onTap: () async {
                                if (await canLaunchUrl(Uri.parse(DataService.cards[index].click_url))) {
                                  launchUrl(Uri.parse(DataService.cards[index].click_url));
                                } else {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PayQRPage("CLICK", DataService.cards[index].click_url, DataService.cards[index])));
                                }
                              },
                              child: Container(
                                height: 40,
                                width: 80,
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    image: DecorationImage(image: AssetImage("assets/images/click.png"),fit: BoxFit.cover)
                                ),
                              ),
                          )),
                          Visibility(visible: DataService.cards[index].click_url.isNotEmpty, child: SizedBox(width: 8,)),
                          Visibility(
                            visible: DataService.cards[index].uzum_url.isNotEmpty,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PayQRPage("UZUM", DataService.cards[index].uzum_url, DataService.cards[index])));
                              },
                              child: Container(
                                height: 40,
                                width: 90,
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    image: DecorationImage(image: AssetImage("assets/images/uzum.png"),fit: BoxFit.cover)
                                ),
                              ),
                          ))
                        ],
                      )
                    ],
                  )),
                );
              },
            ),
             const SizedBox(height: 36),
                /// Rekvizit
                Visibility(
                  visible: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          decoration: BoxDecoration(color: Colors.blue.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            AppLocalizations.of(context).translate("pay_page_factory_number"),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          )),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_factory_stir"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_factory_name"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmInn,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_factory_address"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmAddress,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_factory_bank_number"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmSchet,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_bank"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmBank,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.all(Radius.circular(8))),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).translate("pay_page_mfo"), style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  settings.firmMfo,
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
            /// Contract
           Visibility(
             visible: false,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Container(
                     decoration: BoxDecoration(
                         color: Colors.blue.shade200,
                         borderRadius: const BorderRadius.all(Radius.circular(8))
                     ),
                     padding: const EdgeInsets.all(12), child: Text(AppLocalizations.of(context).translate("pay_page_contract"), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium,)),

                 Padding(
                   padding: const EdgeInsets.only(top: 12),
                   child: Container(
                       decoration: BoxDecoration(
                           color: Colors.grey.shade200,
                           borderRadius: const BorderRadius.all(Radius.circular(8))
                       ),
                       padding: EdgeInsets.all(10), child: Column(
                     mainAxisAlignment: MainAxisAlignment.start,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("${AppLocalizations.of(context).translate("pay_page_contract")} №", style: Theme.of(context).textTheme.bodySmall),
                       const SizedBox(height: 4),
                       Text(settings.contractNum, style: Theme.of(context).textTheme.titleSmall,)
                     ],
                   )),
                 ),

                 Padding(
                   padding: const EdgeInsets.only(top: 12),
                   child: Container(
                       decoration: BoxDecoration(
                           color: Colors.grey.shade200,
                           borderRadius: const BorderRadius.all(Radius.circular(8))
                       ),
                       padding: const EdgeInsets.all(10), child: Column(
                     mainAxisAlignment: MainAxisAlignment.start,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(AppLocalizations.of(context).translate("pay_page_contract_date"), style: Theme.of(context).textTheme.bodySmall),
                       const SizedBox(height: 4),
                       Text(settings.contractDate, style: Theme.of(context).textTheme.titleSmall,)
                     ],
                   )),
                 ),
               ],
             ),
           ),
            const SizedBox(height: 24),
          ],),
        ),
      ),),
    );
  }
  Future<void> getAll(MySettings settings) async {
    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      _isLoading = false;
      if (kDebugMode) {
        print("Error data null or data['ok] != 1");
      }
      return;
    }

    if(mounted){
      setState(() {
        _isLoading = false;
        _shimmer = false;
      });
    }
  }
}

