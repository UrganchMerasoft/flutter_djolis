import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/promo_model.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../services/utils.dart';

class MyPromo extends StatefulWidget {
  const MyPromo({super.key});

  @override
  State<MyPromo> createState() => _MyPromoState();
}

class _MyPromoState extends State<MyPromo> {

  bool _isLoading = false;

  late DateTime date1;
  late DateTime date2;

  List<PromoModel> promo = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllPromo(settings);
    });

  }

  @override
  Widget build(BuildContext context) {

    final settings = Provider.of<MySettings>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).translate("my_discounts")),
      ),
      body: promo.isEmpty ? Align(
          alignment: Alignment.center,
          child: Text(AppLocalizations.of(context).translate("no_promo"), style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w400))) : Column(
        children: [
          Expanded(
            child: _isLoading ? Center(child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              height: 105,
              // width: 110,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context).translate("gl_loading"),
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                    )
                  ],
                ),
              ),
            )) : ListView.builder(
              itemCount: promo.length,
              itemBuilder: (context, index) {
                var progressValue = promo[index].fact_qty / promo[index].val1;
                return Visibility(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("📦 ${promo[index].product_name}", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(promo[index].msg, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(right: 12, left: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${AppLocalizations.of(context).translate("plan")}: ${promo[index].val1}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text("${AppLocalizations.of(context).translate("fact")}: ${promo[index].fact_qty}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                  color: Colors.white,
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progressValue,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                      color: Colors.green.shade400
                                  ),
                                ),
                              ),
                               Padding(
                                padding: const EdgeInsets.only(left: 8, top: 10, right: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    /// Date from
                                    Text(promo[index].date_from),
                                    /// Date to
                                    Text(promo[index].date_to),
                                  ],
                                ),
                              ),
                              Center(
                                heightFactor: 2,
                                child: Text('${Utils.numFormat0_00.format(progressValue * 100)}%', style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Future<void> getAllPromo(MySettings settings) async {
    setState(() {
      _isLoading = true;
    });
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/promo");

    Response res = await post(
      body: jsonEncode({}), uri, headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
    );

    var data;
    try {
      data = jsonDecode(res.body);
    } catch (e) {
      debugPrint(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        print("Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      setState(() {
        promo = (data['d']["promo"] as List).map((item) => PromoModel.fromMapObject(item)).toList();
        debugPrint("My Promo: $promo");
        _isLoading = false;
      });
    }
  }
}
