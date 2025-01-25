import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';
import '../../models/dic_clients.dart';
import '../../services/utils.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  bool _shimmer = true;
  bool _isLoading = false;
  List<DicClients> clients = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllClients(settings);
    });
  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate("clients")),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: Card(
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
                                Text(clients[index].name, style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 12,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 10),
                                Text(clients[index].phone, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){},child: const Icon(Icons.add),),

    );
  }
  Future<void> getAllClients(MySettings settings) async {

    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-get");
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
        debugPrint("getAll Error 1 data null or data['ok] != 1");
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
        debugPrint("getAll 2 Error data null or data['ok] != 1");
      }
      return;
    }

    // debugPrint("$data");
    if (data["ok"] == 1) {
      final List<dynamic> clientsData = data['d'] ?? [];
      clients = clientsData.map((item) => DicClients.fromMapObject(item)).toList();
      debugPrint("Clients: $clients");
      setState(() {});

      if(mounted){
        setState(() {
          _isLoading = false;
          _shimmer = false;
        });

      }
    }
  }

  void addClient(MySettings settings) {

  }
}
