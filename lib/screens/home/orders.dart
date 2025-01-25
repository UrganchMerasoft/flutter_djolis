import 'dart:convert';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _first = true;
  bool _isLoading = false;
  int currentValue = 1;
  List<dynamic> orders = [];
  List<dynamic> ordList = [];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context, listen: false);
    if (_first) {
      _first = false;
      getOrders(settings);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).translate("profile_open_orders")),
      ),
      body: SafeArea(child: Container(
        color: Colors.grey.shade200,
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
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
                      return Text(AppLocalizations.of(context).translate("active_order"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
                    case 2:
                      return Text(AppLocalizations.of(context).translate("archive_order"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
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
              child: orders.where((v) {
                if (currentValue == 1) {
                  return v["status_id"] == 0;
                }
                return v["status_id"] != 0;
              }) .isEmpty ? Center(child: Text(AppLocalizations.of(context).translate("gl_no_data")))
               :  ListView.builder(
                itemCount: orders.length >  2 && currentValue == 2 ? 2 : orders.length ,
                itemBuilder: (context, index) {
                  return Visibility(
                    visible: currentValue == 1 ? (Utils.checkDouble(orders[index]["status_id"]).toInt() == 0) : (Utils.checkDouble(orders[index]["status_id"]).toInt() != 0 ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            openOrder(settings, orders[index]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("# " + orders[index]["id"].toString() + "      ", style: Theme.of(context).textTheme.titleSmall),
                                    Expanded(child: Text(orders[index]["curdate_str"].toString(), style: Theme.of(context).textTheme.titleSmall)),
                                    Text(Utils.myNumFormat0(Utils.checkDouble(orders[index]["itog_summ"])), style: Theme.of(context).textTheme.titleSmall),
                                  ],
                                ),
                                const SizedBox(height: 12,),
                                Row(
                                  children: [
                                    Expanded(child: Text(orders[index]["notes"], style: Theme.of(context).textTheme.bodyMedium,)),
                                    getStatusText(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                    getStatusIcon(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void getOrders(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-orders");
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
      // if (context.mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      // }
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
      setState(() {
        orders = data!["d"]["ords"];
        ordList = data!["d"]["list"];
        _isLoading = false;
      });
    }
  }

  void openOrder(MySettings settings, order) async {
    debugPrint("$ordList");
    List<dynamic> list = ordList.where((v) => v["doc_id"] == order["id"]).toList();
    debugPrint("$list");

    showDialog(context: context, builder: (BuildContext context) {
      return Dialog(child: Container(
        color: Colors.grey.shade200,
        height: list.length > 0 ? MediaQuery.of(context).size.height * 0.8 : 180,
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(visible: list.length > 0, child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Text("Список товаров", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
              )),
              Expanded(
                child: ListView.builder(itemCount: list.length, itemBuilder: (context, index) {
                  return Card(child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list[index]["name"].toString(), style: Theme.of(context).textTheme.titleSmall,),
                        const SizedBox(height: 4,),
                        Row(
                          children: [
                            Text(list[index]["qty"].toString()),
                            Text("  x  ", style: Theme.of(context).textTheme.bodySmall),
                            Text(Utils.myNumFormat0(Utils.checkDouble(list[index]["price"])), style: Theme.of(context).textTheme.bodySmall),
                            Expanded(child: Text(" = ", style: Theme.of(context).textTheme.bodySmall)),
                            Text(Utils.myNumFormat0(Utils.checkDouble(list[index]["summ"])))
                          ],
                        )
                      ],),
                  ));
                }),
              )
            ],
          ),
        ),
      ));
    });
  }

  getStatusText(MySettings settings, int status_id) {
    if (status_id == 1) {
      return Text(AppLocalizations.of(context).translate("accepted"), style: const TextStyle(color: Colors.green, fontSize: 12),);
    }
    if (status_id == 9) {
      return Text(AppLocalizations.of(context).translate("denied"), style: const TextStyle(color: Colors.red, fontSize: 12),);
    }
    return Text(AppLocalizations.of(context).translate("new"), style: const TextStyle(color: Colors.blue, fontSize: 12),);
  }

  getStatusIcon(MySettings settings, int status_id) {
    if (status_id == 1) {
      return const Icon(Icons.check_box, color: Colors.green, size: 16);
    }
    if (status_id == 1) {
      return const Icon(Icons.close, color: Colors.red, size: 16);
    }
    return const Icon(Icons.check, color: Colors.blue, size: 16);
  }
}
