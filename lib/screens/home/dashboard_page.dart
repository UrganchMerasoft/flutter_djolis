import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/new_click_model.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_localizations.dart';
import '../../../core/mysettings.dart';
import '../../../models/malumot_model.dart';
import '../../../services/data_service.dart';
import '../../../services/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _shimmer = true;
  bool _isLoading = false;
  List<NewClickModel>? clickList;
  String clickUrl = "";
  TextEditingController clickController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAll(settings);
      newClick(settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: _shimmer ? shimmerList(settings) : CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.grey.shade200,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InfoContainer(
                          text1: "${AppLocalizations.of(context).translate("cashback")}:",
                          text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.cashBack.toDouble())
                      ),
                      const SizedBox(width: 10),
                      InfoContainer(
                          text1: "${AppLocalizations.of(context).translate("debt")}:",
                          text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.debt.toDouble())
                      ),
                      const SizedBox(width: 10),
                      InfoContainer(
                          text1: "${AppLocalizations.of(context).translate("credit_limit")}:",
                          text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.creditLimit.toDouble())
                      ),
                    ],
                  ),
                ),
              ),
            ),
            expandedHeight: 90,  // Adjust height as needed
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade300,
                    ),
                      child:  Center(child: Text(AppLocalizations.of(context).translate("dash_pay"),style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16,),))),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => PayQRPage("PAYME", "DataService.cards[index].payme_url", DataService.cards[index])));
                          //launchUrl(Uri.parse(DataService.cards[index].payme_url));
                        },
                        child: Container(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          height: 70,
                          width: 110,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Image(image: AssetImage("assets/images/img.png")),
                        )
                      ),

                      InkWell(
                        onTap: () {
                          showDialog(context: context, builder: (BuildContext context) => AlertDialog(
                            actions: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Center(child: Image(image: AssetImage("assets/images/click.png"), width: 180,)),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                      child: Form(
                                        child: TextFormField(
                                          controller: clickController,
                                          validator: (v) => v!.isEmpty ? AppLocalizations.of(context).translate("enter_summ"): null,
                                          keyboardType: const TextInputType.numberWithOptions(),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            fillColor: Colors.grey.shade200,
                                            labelText: AppLocalizations.of(context).translate("enter_summ"),
                                            focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                                            border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                                            enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: const Size(120, 45),
                                                backgroundColor: Colors.red.shade400,
                                              ),
                                              onPressed: (){
                                                Navigator.pop(context);
                                              }, child: Text(AppLocalizations.of(context).translate("gl_cancel"))),
                                          const SizedBox(width: 20),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  fixedSize: const Size(120, 45),
                                                  backgroundColor: Colors.blue.shade600
                                              ),
                                              onPressed: (){
                                                launchUrl(Uri.parse(clickUrl));
                                              }, child: Text(AppLocalizations.of(context).translate("dash_do_pay")))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ));
                          // launchUrl(Uri.parse(clickUrl));
                        },
                        child:  Container(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          height: 70,
                          width: 110,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Image(image: AssetImage("assets/images/click.png")),
                        )
                      ),
                      InkWell(
                        onTap: () {},
                        child:  Container(
                          height: 70,
                          width: 110,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Image(image: AssetImage("assets/images/salary.png")),
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
              child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade300,
                  ),
                  child:  Center(child: Text(AppLocalizations.of(context).translate("dash_info"),style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16,)))),
            ),
          ),

          SliverList(
              key: PageStorageKey<String>('controllerA'),
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (index == DataService.malumot.length) {
                      return const SizedBox(height: 70);
                    }
                return DataService.malumot.isEmpty ? Center(child: Text(AppLocalizations.of(context).translate("list_empty")),) :Container(
                  margin: const EdgeInsets.all(8),
                  height: 110,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DataService.malumot[index].doc_type == "order" ? AppLocalizations.of(context).translate("dash_ord") : AppLocalizations.of(context).translate("dash_pay"), style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                              Text("${DataService.malumot[index].summ}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                           const SizedBox(height: 10),
                           Visibility(
                              visible: DataService.malumot[index].notes.isEmpty,
                              child: const SizedBox(height: 25)),
                          Visibility(
                            visible: DataService.malumot[index].notes.isNotEmpty,
                            child: SizedBox(
                              height: 40,
                              child: Text(DataService.malumot[index].notes, maxLines: 2),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 10,),
                              Text(DataService.malumot[index].curtime_str, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: DataService.malumot.length + 1
          ))
        ],
      ),
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
        debugPrint("Error data null or data['ok] != 1");
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

    if (data["ok"] == 1) {

      DataService.malumot = (data['d']["malumot"] as List?)?.map((item) => MalumotModel.fromMapObject(item)).toList() ?? [];

      DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]) ;
      DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);

      if(mounted){
        setState(() {
          _isLoading = false;
          _shimmer = false;
        });

      }
    }
  }

  Future<void> newClick(MySettings settings) async {

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-click");
    Response? res;
    try {
      res = await post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "client_id": 871,
          "summ": 2000,
        })
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error data null or data['ok] != 1 !");
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        debugPrint("Error data null or data['ok] != 1 !!");
      }
      return;
    }

    if (data["ok"] == 1) {
      DataService.newClick = [NewClickModel.fromJson(data['d'])];
      debugPrint("\x1B[34mnew-click: ${DataService.newClick}");
      /// \x1B[34mn  <- printni ichida shu kod yozilsa print ichidagi ma'lumot rangli bo'lib chiqadi!
      for (var clickModel in DataService.newClick) {
        clickUrl = clickModel.url;
      }
    }
  }



  Widget shimmerList(MySettings settings) {
    return Column(
      children: [
        Expanded(child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),

        Expanded(child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),

        Expanded(child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),

        Expanded(child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ))
      ],
    );
  }
}



class InfoContainer extends StatelessWidget {
  final String text1;
  final String text2;
  const InfoContainer({
    super.key,required this.text1, required this.text2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Text(maxLines: 1,text1, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(text2, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

