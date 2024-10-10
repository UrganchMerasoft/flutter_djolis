import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/models/dic_balance.dart';
import 'package:flutter_djolis/models/doc_akt_sverka.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';
import '../../models/dic_ord.dart';

class AktSverka extends StatefulWidget {
  const AktSverka({super.key});

  @override
  State<AktSverka> createState() => _AktSverkaState();
}

class _AktSverkaState extends State<AktSverka> {
  List<Order> order = [];
  List<DocAktSverka> aktSvr = [];
  List<DicBalance> balance = [];

  bool _isLoading = false;

  late DateTime date1;
  late DateTime date2;
  TextEditingController dateController1 = TextEditingController();
  TextEditingController dateController2 = TextEditingController();

  Future<void> _selectDate(BuildContext context, MySettings settings, int date_index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: date_index == 1 ? date1 : date2,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        if (date_index == 1) {
          date1 = pickedDate;
        } else {
          date2 = pickedDate;
        }
        dateController1.text = Utils.myDateFormat(Utils.formatDDMMYYY, date1);
        dateController2.text = Utils.myDateFormat(Utils.formatDDMMYYY, date2);
        getAllAktSverka(settings);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllAktSverka(settings);
    });
    date1 = DateTime.now().subtract(const Duration(days: 30));
    date2 = DateTime.now();
    dateController1.text = Utils.myDateFormat(Utils.formatDDMMYYY, date1);
    dateController2.text = Utils.myDateFormat(Utils.formatDDMMYYY, date2);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
        child: Column(
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () {
                  setState(() {
                    date1 = date1.subtract(Duration(days: 10));
                    dateController1.text = Utils.myDateFormat(Utils.formatDDMMYYY, date1);
                  });
                  getAllAktSverka(settings);
                }, icon: Icon(Icons.chevron_left)),
                Expanded(
                  child: TextField(
                    controller: dateController1,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      await _selectDate(context, settings, 1);
                      },
                    readOnly: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: AppLocalizations.of(context).translate("akt_sverka_from"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: dateController2,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      await _selectDate(context, settings, 2);
                    },
                    readOnly: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: AppLocalizations.of(context).translate("akt_sverka_to"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    getAllAktSverka(settings);
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize:const  Size(62, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Chat
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF5F5F5),
                ),
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
                  itemCount: aktSvr.length,
                  itemBuilder: (BuildContext context, int index) {

                    final currentAktSvr = aktSvr[index];
                    if (currentAktSvr.docType == "dolg") {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: Text("${AppLocalizations.of(context).translate("balance_morning")} ${dateController1.text}:   ${Utils.myNumFormat0(currentAktSvr.balans)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: currentAktSvr.balans < 0 ? Colors.red : null) ),),
                      );
                    }


                    if (currentAktSvr.docType == "pay") {
                      return InkWell(
                        onTap: () {
                          openAkt(settings, currentAktSvr);
                        },
                        child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                        child: Stack(
                          children: [
                            CustomPaint(painter: MyChatBubbleLeft(currentAktSvr), size: const Size(270, 90),),
                            SizedBox(
                              height: 106,
                              width: 262,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 38, top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('${AppLocalizations.of(context).translate("akt_sverka_" + currentAktSvr.docType + (currentAktSvr.pay_type == "" ? "" : "_") + currentAktSvr.pay_type)}: № ${currentAktSvr.docNum}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,),
                                          ),
                                        ),

                                        Text('${Utils.numFormat0.format(currentAktSvr.summ)}', style: const TextStyle(fontWeight: FontWeight.bold,),),
                                      ],
                                    ),
                                    Visibility(visible: currentAktSvr.bank_info.isNotEmpty, child: Text(currentAktSvr.bank_info, style: const TextStyle(fontSize: 10), maxLines: 1)),

                                    SizedBox(height: 2,),
                                    Text('${AppLocalizations.of(context).translate("akt_sverka_notes")}: ${currentAktSvr.notes}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                    SizedBox(height: 2,),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14),
                                        const SizedBox(width: 6),
                                        Text('Т.А.: ${currentAktSvr.baseName}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                      ],
                                    ),
                                    SizedBox(height: 2,),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14),
                                        const SizedBox(width: 6),
                                        Text(currentAktSvr.enteredTime, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 32,
                              bottom: 0,
                              child: Text("${AppLocalizations.of(context).translate("balance")}: ${Utils.numFormat0.format(currentAktSvr.balans)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: currentAktSvr.balans < 0 ? Colors.red : null))),
                          ],
                        ),
                                            ),
                      );
                    } else {
                      return InkWell(
                        onTap: () {
                          openAkt(settings, currentAktSvr);
                        },
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Stack(
                            children: [
                              CustomPaint(painter: MyChatBubbleRight(currentAktSvr), size: const Size(280, 82),),
                              SizedBox(
                                height: 110,
                                width: 300,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, right: 52, top: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              currentAktSvr.docType == "whinv"&&currentAktSvr.summ > 0 ?  '${AppLocalizations.of(context).translate("akt_sverka_whinv_ret")}: № ${currentAktSvr.docNum}'
                                                  : '${AppLocalizations.of(context).translate("akt_sverka_" + currentAktSvr.docType + (currentAktSvr.pay_type == "" ? "" : "_") + currentAktSvr.pay_type)}: № ${currentAktSvr.docNum}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),

                                          Text('${Utils.numFormat0.format(-1*currentAktSvr.summ)}', style: const TextStyle(fontWeight: FontWeight.bold,),),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('${AppLocalizations.of(context).translate("akt_sverka_notes")}: ${currentAktSvr.notes}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 14),
                                          const SizedBox(width: 6),
                                          Text('Т.А.: ${currentAktSvr.baseName}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14),
                                          const SizedBox(width: 6),
                                          Text(currentAktSvr.enteredTime, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 54,
                                bottom: 10,
                                child: Text("${AppLocalizations.of(context).translate("balance")}: ${Utils.numFormat0.format(currentAktSvr.balans)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: currentAktSvr.balans < 0 ? Colors.red : null)),
                              ),
                            ],
                          ),
                                              ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getAllAktSverka(MySettings settings) async {
    setState(() {
      _isLoading = true;
    });
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/sverka");

    Response res = await post(
      body: jsonEncode({
        "date1": Utils.myDateFormat(Utils.formatYYYYMMdd, date1),
        "date2": Utils.myDateFormat(Utils.formatYYYYMMdd, date2)
      }),
      uri,
      headers: <String, String>{
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

        aktSvr = (data['d']["akt"] as List).map((item) => DocAktSverka.fromMapObject(item)).toList();
        var balanceData = data['d']["balans"];
        double balans = Utils.checkDouble(balanceData["dolg1"]);
        aktSvr.insert(0, DocAktSverka(balans: 0, baseId: 0, baseName: "", deliverName: "", docType: "dolg", enteredTime: "", id: 0, isBn: 0, isNal: 0, notes: "", summ: balans, docNum: "", returnType: "", whInvId: 0, pay_type: "", bank_info: "") );
        aktSvr[0].balans = aktSvr[0].summ;
        for (var i = 1; i < aktSvr.length; i++) {
          balans += aktSvr[i].summ;
          aktSvr[i].balans = balans;
        }

        if (balanceData is List) {
          balance = balanceData.map((item) => DicBalance.fromMapObject(item as Map<String, dynamic>)).toList();
        } else if (balanceData is Map) {
          balance = [DicBalance.fromMapObject(balanceData.cast<String, dynamic>())];
        } else {
          balance = [];
        }

        _isLoading = false;
      });
    }
  }

  void openAkt(MySettings settings, DocAktSverka currentAktSvr) async {
    List<dynamic> list = [];

    if (currentAktSvr.whInvId != 0&&currentAktSvr.summ > 0) {
      Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-whinv-list");
      Response res = await post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            "lang": settings.locale.languageCode,
            "phone": settings.clientPhone,
            "Authorization": "Bearer ${settings.token}",
          },
          body: jsonEncode({
            "id": currentAktSvr.whInvId
          })
      );

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
        return;
      }

      if (data["ok"] == 1) {
        list = data["d"];
      }
    }

    if (list.isEmpty&&currentAktSvr.returnType == ""&&currentAktSvr.notes == "") return;

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
              Visibility(
                visible: currentAktSvr.returnType != "",
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(currentAktSvr.returnType, style: const TextStyle(color: Colors.red),),
                ),
              ),
              Visibility(visible: currentAktSvr.notes.isNotEmpty, child: Text(AppLocalizations.of(context).translate("akt_sverka_notes"), style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,)),
              const SizedBox(height: 4,),
              Text(currentAktSvr.notes, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Visibility(visible: list.length > 0, child:  Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Text(AppLocalizations.of(context).translate("akt_sverka_prod_list"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
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
                            Text(list[index]["qty"]),
                            Text("  x  ", style: Theme.of(context).textTheme.bodySmall),
                            Text(Utils.myNumFormat0(Utils.checkDouble(list[index]["price_up"])), style: Theme.of(context).textTheme.bodySmall),
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

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ));
  }
}


class MyChatBubbleLeft extends CustomPainter {
  final DocAktSverka currentAktSvr;
  MyChatBubbleLeft(this.currentAktSvr);

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.1173225, 0);
    path_0.cubicTo(size.width * 0.1173225, 0, size.width * 0.03812250, 0, size.width * 0.01794193, 0);
    path_0.cubicTo(size.width * -0.002232279, 0, size.width * -0.006896821, size.height * 0.05335381, size.width * 0.01173543, size.height * 0.1067079);
    path_0.cubicTo(size.width * 0.03036768, size.height * 0.1600619, size.width * 0.1104257, size.height * 0.3379083, size.width * 0.1173225, size.height * 0.3912619);
    path_0.cubicTo(size.width * 0.1242129, size.height * 0.4446155, size.width * 0.1173225, 0, size.width * 0.1173225, 0);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Colors.blueGrey.shade100;
    canvas.drawPath(path_0, paint_0_fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.1721225, size.height * 1.000002);
    path_1.cubicTo(size.width * 0.1397871, size.height * 1.000002, size.width * 0.09451607, size.height * 0.9238131, size.width * 0.09451607, size.height * 0.7333345);
    path_1.lineTo(size.width * 0.1721225, size.height * 0.7333345);
    path_1.lineTo(size.width * 0.1721225, size.height * 1.000002);
    path_1.close();

    Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color =  Colors.blueGrey.shade100;
    canvas.drawPath(path_1, paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(size.width * 0.1721225, 0);
    path_2.lineTo(size.width * 0.09451607, 0);
    path_2.lineTo(size.width * 0.09451607, size.height * 0.7333345);
    path_2.lineTo(size.width * 0.1721225, size.height * 0.7333345);
    path_2.lineTo(size.width * 0.1721225, 0);
    path_2.close();

    Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color =  Colors.blueGrey.shade100;
    canvas.drawPath(path_2, paint_2_fill);

    Path path_3 = Path();
    path_3.moveTo(size.width, size.height * 0.1200000);
    path_3.cubicTo(size.width, size.height * 0.05372583, size.width * 0.9826679, 0, size.width * 0.9612893, 0);
    path_3.lineTo(size.width * 0.1677418, 0);
    path_3.lineTo(size.width * 0.1677418, size.height);
    path_3.lineTo(size.width * 0.9612893, size.height);
    path_3.cubicTo(size.width * 0.9826679, size.height, size.width, size.height * 0.9462738, size.width, size.height * 0.8800000);
    path_3.lineTo(size.width, size.height * 0.1200000);
    path_3.close();

    Paint paint_3_fill = Paint()..style = PaintingStyle.fill;
    paint_3_fill.color =  Colors.blueGrey.shade100;
    canvas.drawPath(path_3, paint_3_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


class MyChatBubbleRight extends CustomPainter {
  final DocAktSverka currentAktSvr;
  MyChatBubbleRight(this.currentAktSvr);

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.8826786, 0);
    path_0.cubicTo(size.width * 0.8826786, 0, size.width * 0.9618786, 0, size.width * 0.9820571, 0);
    path_0.cubicTo(size.width * 1.002232, 0, size.width * 1.006896, size.height * 0.05335378, size.width * 0.9882643, size.height * 0.1067078);
    path_0.cubicTo(size.width * 0.9696321, size.height * 0.1600611, size.width * 0.8895750, size.height * 0.3379078, size.width * 0.8826786, size.height * 0.3912622);
    path_0.cubicTo(size.width * 0.8757857, size.height * 0.4446156, size.width * 0.8826786, 0, size.width * 0.8826786, 0);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Color(0xffFFC5C5).withOpacity(1.0);
    if (currentAktSvr.docType == "whinv"&&currentAktSvr.summ > 0) paint_0_fill.color = Colors.green.shade100.withOpacity(1.0);
    canvas.drawPath(path_0, paint_0_fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.8278786, size.height * 1.000001);
    path_1.cubicTo(size.width * 0.8602143, size.height * 1.000001, size.width * 0.9054821, size.height * 0.9238111, size.width * 0.9054821, size.height * 0.7333333);
    path_1.lineTo(size.width * 0.8278786, size.height * 0.7333333);
    path_1.lineTo(size.width * 0.8278786, size.height * 1.000001);
    path_1.close();

    Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
    paint_1_fill.color = Color(0xffFFC5C5).withOpacity(1.0);
    if (currentAktSvr.docType == "whinv"&&currentAktSvr.summ > 0) paint_1_fill.color = Colors.green.shade100.withOpacity(1.0);
    canvas.drawPath(path_1, paint_1_fill);

    Path path_2 = Path();
    path_2.moveTo(size.width * 0.8278786, 0);
    path_2.lineTo(size.width * 0.9054821, 0);
    path_2.lineTo(size.width * 0.9054821, size.height * 0.7333344);
    path_2.lineTo(size.width * 0.8278786, size.height * 0.7333344);
    path_2.lineTo(size.width * 0.8278786, 0);
    path_2.close();

    Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
    paint_2_fill.color = Color(0xffFFC5C5).withOpacity(1.0);
    if (currentAktSvr.docType == "whinv"&&currentAktSvr.summ > 0) paint_2_fill.color = Colors.green.shade100.withOpacity(1.0);
    canvas.drawPath(path_2, paint_2_fill);

    Path path_3 = Path();
    path_3.moveTo(0, size.height * 0.1200000);
    path_3.cubicTo(0, size.height * 0.05372578, size.width * 0.01733089, 0, size.width * 0.03870964, 0);
    path_3.lineTo(size.width * 0.8322571, 0);
    path_3.lineTo(size.width * 0.8322571, size.height);
    path_3.lineTo(size.width * 0.03870964, size.height);
    path_3.cubicTo(size.width * 0.01733089, size.height, 0, size.height * 0.9462744, 0, size.height * 0.8800000);
    path_3.lineTo(0, size.height * 0.1200000);
    path_3.close();

    Paint paint_3_fill = Paint()..style = PaintingStyle.fill;
    paint_3_fill.color = Color(0xffFFC5C5).withOpacity(1.0);
    if (currentAktSvr.docType == "whinv"&&currentAktSvr.summ > 0) paint_3_fill.color = Colors.green.shade100.withOpacity(1.0);
    canvas.drawPath(path_3, paint_3_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


