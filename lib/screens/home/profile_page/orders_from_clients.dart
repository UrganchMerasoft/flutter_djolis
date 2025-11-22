import 'dart:convert';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../common/photo.dart';

class OrdersFromClients extends StatefulWidget {
  const OrdersFromClients({super.key});

  @override
  State<OrdersFromClients> createState() => _OrdersFromClientsState();
}

class _OrdersFromClientsState extends State<OrdersFromClients> {
  bool _first = true;
  bool _isLoading = true;
  List<dynamic> orders = [];
  List<dynamic> ordList = [];
  List<dynamic> files = [];

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
        title: Text(AppLocalizations.of(context).translate("profile_open_orders_from_client")),
      ),
      body: SafeArea(child: Container(
        color: Colors.grey.shade200,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : (orders.isEmpty ? Center(child: Text(AppLocalizations.of(context).translate("gl_no_data")))
                  :  ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return Padding(
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
                                    Text("# ${orders[index]["id"]}    ", style: Theme.of(context).textTheme.titleSmall),
                                    Expanded(child: Text(orders[index]["mijoz_name"].toString(), style: Theme.of(context).textTheme.titleSmall)),
                                    Text(Utils.myNumFormat0(Utils.checkDouble(orders[index]["itog_summ"])), style: Theme.of(context).textTheme.titleSmall),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(orders[index]["mijoz_phone"], style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text(orders[index]["curdate_str"], style: Theme.of(context).textTheme.bodySmall,)),
                                    getStatusText(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                    const SizedBox(width: 5),
                                    getStatusIcon(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
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
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-mijoz-orders");
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
        print("Error data null or data['ok] != 1");
      }
      return;
    }
    if (data["ok"] == 1) {
      setState(() {
        orders = data!["d"]["ords"];
        ordList = data["d"]["list"];
        files = data["d"]["files"];
        _isLoading = false;
      });
    }
  }


  void openOrder(MySettings settings, order) async {
    debugPrint("$ordList");
    List<dynamic> list =
    ordList.where((v) => v["doc_id"] == order["id"]).toList();
    debugPrint("$list");

    List<dynamic> orderFiles =
    files.where((f) => f["doc_id"] == order["id"]).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          color: Colors.grey.shade200,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (list.isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                    child: Text(AppLocalizations.of(context).translate("akt_sverka_prod_list"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      ...list.map((item) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item["pic_url"] != null && item["pic_url"].toString().isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoPage(url: item["pic_url"], title: item["name"])));
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover, imageUrl: item["pic_url"],
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(Icons.image, size: 50, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item["name"].toString(), style: Theme.of(context).textTheme.titleSmall),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(item["qty"].toString()),
                                          Text("  x  ", style: Theme.of(context).textTheme.bodySmall),
                                          Text(Utils.myNumFormat0(Utils.checkDouble(item["price"])), style: Theme.of(context).textTheme.bodySmall),
                                          Expanded(child: Text(" = ", style: Theme.of(context).textTheme.bodySmall)),
                                          Text(Utils.myNumFormat0(Utils.checkDouble(item["summ"]))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (list.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${AppLocalizations.of(context).translate("gl_total")}: ", style: Theme.of(context).textTheme.titleSmall),
                              Text(Utils.myNumFormat0(list.fold(0.0, (sum, item) => sum + Utils.checkDouble(item["summ"]))),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      if (orderFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(child: Text(AppLocalizations.of(context).translate("order_screenshots"), style: Theme.of(context).textTheme.titleMedium)),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: orderFiles.map((f) {
                            return FutureBuilder<String?>(
                              future: getTelegramFileUrl(settings, f["fileId"]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Icon(Icons.broken_image, size: 150, color: Colors.grey);
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoPage(url: snapshot.data!, title: "Screenshot")),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(fit: BoxFit.fitHeight, imageUrl: snapshot.data!),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        )

                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  getStatusText(MySettings settings, int status_id) {
    if (status_id == 0) {
      return Text(AppLocalizations.of(context).translate("new"), style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),);
    }
    if (status_id == 1) {
      return Text(AppLocalizations.of(context).translate("accepted"), style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),);
    }
    if (status_id == 2) {
      return Text(AppLocalizations.of(context).translate("sent"), style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),);
    }
    if (status_id == 3) {
      return Text(AppLocalizations.of(context).translate("delivered"), style:  const TextStyle(color: Colors.brown, fontSize: 13, fontWeight: FontWeight.bold),);
    }
    if (status_id == 9) {
      return Text(AppLocalizations.of(context).translate("denied"), style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),);
    }
    return const Text("Unknown", style: TextStyle(color: Colors.blue, fontSize: 12),);
  }

  getStatusIcon(MySettings settings, int statusId) {
    if (statusId == 0) {
      return const Icon(Icons.timer_outlined, color: Colors.orange, size: 18);
    }
    if (statusId == 1) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 18);
    }
    if (statusId == 2) {
      return const Icon(Icons.send, color: Colors.blue, size: 18);
    }
    if (statusId == 3) {
      return  const Icon(Icons.delivery_dining, color: Colors.brown, size: 18);
    }
    if (statusId == 9) {
      return const Icon(Icons.cancel, color: Colors.red, size: 18);
    }
  }

  Future<String?> getTelegramFileUrl(MySettings settings, String fileId) async {
    try {
      final uri = Uri.parse("https://api.telegram.org/bot${settings.botToken}/getFile?file_id=$fileId");
      final res = await get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["ok"] == true) {
          final filePath = data["result"]["file_path"];
          final fileUrl = "https://api.telegram.org/file/bot${settings.botToken}/$filePath";
          return fileUrl;
        }
      }
      return null;
    } catch (e) {
        debugPrint("Telegramdan rasm olishda xato: $e");
      return null;
    }
  }
}
