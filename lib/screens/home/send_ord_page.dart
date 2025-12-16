import 'dart:async';
import 'dart:convert';

import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/payed_order_model.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/new_click_model.dart';
import '../../models/new_payme_model.dart';
import '../../services/data_service.dart';
import '../../services/utils.dart';

class SendOrdPage extends StatefulWidget {
  final bool hasPromo;
  const SendOrdPage({super.key, required this.hasPromo});


  @override
  State<SendOrdPage> createState() => _SendOrdPageState();
}

class _SendOrdPageState extends State<SendOrdPage> {

  TextEditingController networkController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController deliveryDateController = TextEditingController();
  TextEditingController debtNotesController = TextEditingController();
  ExpansionTileController debtController = ExpansionTileController();
  TextEditingController commentController = TextEditingController();
  MoneyMaskedTextController paymeController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: ' ', precision: 0);
  MoneyMaskedTextController clickController = MoneyMaskedTextController(decimalSeparator: ' ', thousandSeparator: ' ', precision: 0);

  String clickUrl = "";
  String paymeUrl = "";
  String networkUrl = "";
  List<NewPaymeModel> paymeList = [];
  List<PayedOrderModel> payedOrders = [];
  late DateTime date1;
  late DateTime deliveryDate;
  bool checker1 = false;
  bool checker2 = false;
  bool _isAksiyaChecked = false;
  int selectPay = 0;
  bool _shimmer = true;
  double totalSumm = 0;
  bool isSending = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      paymeController.text = ((settings.itogSumm * settings.curRate / 500).round() * 500).toString();
      clickController.text = ((settings.itogSumm * settings.curRate / 500).round() * 500).toString();
      networkController.text = settings.itogSumm.toString();
      payedOrder(settings);
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_shimmer) {
          payedOrder(settings);
        } else {
          timer.cancel();
        }
      });

      if(settings.ordUuid == ""){
        settings.ordUuid = Utils.myUUID();
        settings.saveAndNotify();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    bool isVisible = shouldBeVisible(settings.today);
    return Container(
      decoration:  const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/back_wallpaper.png"),fit: BoxFit.fill)
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(AppLocalizations.of(context).translate("verify_ord")),
          centerTitle: true,
        ),
        body: _shimmer ? shimmerList(settings) : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: settings.clientPhone != "+998977406675",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Visibility(
                          child: SizedBox(height: 20)),
                      Visibility(
                        child: ExpansionTile(
                          collapsedIconColor: Theme.of(context).primaryColor,
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade400)),
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          collapsedBackgroundColor: Colors.white.withValues(alpha: 0.5),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("pay_on_delivery"),
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade200 : Colors.black)),
                            ],
                          ),
                          trailing: Icon(selectPay == 1 ? Icons.check_circle : Icons.circle_outlined, size: 23,),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              if (expanded) {
                                selectPay = 1;
                                checker2 = false;
                              } else if (selectPay == 1) {
                                selectPay = 0;
                              }
                              debugPrint("Pay on delivery: ${selectPay}");
                            });
                          },
                          children: [
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            /// Date controller
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
                              child: TextFormField(
                                controller: deliveryDateController,
                                readOnly: true,
                                onTap: () async {
                                  await _selectDeliveryDate(context, settings);
                                },
                                decoration: InputDecoration(
                                  suffixIcon: const Icon(Icons.calendar_month),
                                  isDense: true,
                                  fillColor: Colors.grey.shade200,
                                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                                  labelText: AppLocalizations.of(context).translate("enter_date"),
                                  focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      Visibility(
                          visible: settings.clientPhone.startsWith("+971"),
                          child: const SizedBox(height: 20)),
                      Visibility(
                        visible: settings.clientPhone.startsWith("+971"),
                        child: ExpansionTile(
                          collapsedIconColor: Theme.of(context).primaryColor,
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade400)),
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          collapsedBackgroundColor: Colors.white.withValues(alpha: 0.5),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("card_payment"),
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade200 : Colors.black)),
                              Text("  (${AppLocalizations.of(context).translate("paid")}: ${Utils.numFormat0_00.format(totalSumm / settings.curRate)})", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800)),
                            ],
                          ),
                          trailing: Icon(selectPay == 2 ? Icons.check_circle : Icons.circle_outlined, size: 23),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              if (expanded) {
                                selectPay = 2;
                                checker1 = false;
                              } else if (selectPay == 2) {
                                selectPay = 0;
                              }
                              debugPrint("To'lash: ${selectPay}");
                            });
                          },
                          children: [
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: settings.clientPhone.startsWith("+971")
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: (){
                                        networkPayDialog(context, settings);
                                      },
                                      child: Container(
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        height: 60,
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          border: Border.all(color: Colors.white),
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Center(child: isSending ? const CircularProgressIndicator() : const Image(image: AssetImage("assets/icons/credit_card.png"), height: 70)),
                                            const SizedBox(width: 15),
                                            isSending ? Text(AppLocalizations.of(context).translate("wait")): Text(AppLocalizations.of(context).translate("card_payment"), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: (){
                                        paymeDialog(context, settings);
                                      },
                                      child: Container(
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        height: 50,
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            image: const DecorationImage(image: AssetImage("assets/images/img.png"))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: (){
                                        clickDialog(context, settings);
                                      },
                                      child: Container(
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        height: 50,
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            image: const DecorationImage(image: AssetImage("assets/images/click.png"))),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                key: PageStorageKey<String>('controllerA'),
                                itemCount: payedOrders.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(payedOrders[index].name, style: Theme.of(context).textTheme.titleMedium),
                                            Text(" (${payedOrders[index].curtime})", style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                        Text(Utils.numFormat0.format(payedOrders[index].summ), style: Theme.of(context).textTheme.bodyLarge),
                                      ],
                                    ),
                                  );
                                }
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white)),
                        height: 60,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, right: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(AppLocalizations.of(context).translate("pay_by_cashback"),
                                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade200 : Colors.black)),
                                  Text("  ( ${Utils.numFormat0_00.format(DataService.cashBack / settings.curRate)})", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800)),
                                ],
                              ),
                              Radio(
                                activeColor: Colors.white,
                                value: 3,
                                groupValue: selectPay,
                                onChanged: (value) {
                                  setState(() {
                                    selectPay = value!;
                                    checker1 = false;
                                    checker2 = false;
                                    debugPrint("selectPay Cashback: $selectPay");
                                    debugPrint("Cashback: ${Utils.numFormat0_00.format(DataService.cashBack / settings.curRate)}");
                                    if(DataService.cashBack / settings.curRate < settings.itogSumm){
                                      showRedSnackBar(AppLocalizations.of(context).translate("lack_of_cashback"));
                                    }
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                          visible: isVisible,
                          child: const SizedBox(height: 20)),
                      Visibility(
                        visible: isVisible,
                        child: ExpansionTile(
                          collapsedIconColor: Theme.of(context).primaryColor,
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade400)),
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          collapsedBackgroundColor: Colors.white.withValues(alpha: 0.5),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).translate("in_debt"),
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade200 : Colors.black)),
                            ],
                          ),
                          trailing: Icon(selectPay == 4 ? Icons.check_circle : Icons.circle_outlined, size: 23),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              if (expanded) {
                                selectPay = 4;
                                checker2 = false;
                              } else if (selectPay == 4) {
                                selectPay = 0;
                              }
                              debugPrint("In debt: ${selectPay}");
                            });
                          },
                          children: [
                            Divider(color: Colors.grey.shade300, thickness: 1),
                            /// Date controller
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
                              child: TextFormField(
                                controller: dateController,
                                readOnly: true,
                                onTap: () async {
                                  await _selectDate(context, settings);
                                },
                                decoration: InputDecoration(
                                  suffixIcon: const Icon(Icons.calendar_month),
                                  isDense: true,
                                  fillColor: Colors.grey.shade200,
                                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                                  labelText: AppLocalizations.of(context).translate("enter_date"),
                                  focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            /// Debt Note Controller
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
                              child: TextFormField(
                                controller: debtNotesController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  fillColor: Colors.grey.shade100,
                                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                                  labelText: AppLocalizations.of(context).translate("debt_notes"),
                                  focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                                  border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white),
                            const SizedBox(width: 5),
                            Expanded(child: Text(AppLocalizations.of(context).translate("cashback_warning"), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(
                    height: 20,
                    child: Text(
                      AppLocalizations.of(context).translate("comment"),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    )),
                /// Notes Controller
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: TextFormField(
                    controller: commentController,
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(14)),
                      labelText: AppLocalizations.of(context).translate("akt_sverka_notes"),
                      labelStyle: TextStyle(color: Colors.black),
                      focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.blue), borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 5),
                      Expanded(child: Text(AppLocalizations.of(context).translate("notes_warning"), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Visibility(
                  visible: widget.hasPromo,
                  child: Row(
                    children: [
                      Checkbox(
                        activeColor: Theme.of(context).primaryColor,
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        value: _isAksiyaChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAksiyaChecked = value!;
                          });
                        },
                      ),
                      const SizedBox(width: 5),
                      Text(AppLocalizations.of(context).translate("hasPromoAdd"), style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white)
              ),
              height: 190,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text("${AppLocalizations.of(context).translate("gl_summa_ord")}:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        Text(
                          Utils.numFormat0.format(settings.itogSumm),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            "${AppLocalizations.of(context).translate("cashback")}:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        Text((settings.clientPhone.startsWith("+998") && selectPay != 1) ? Utils.numFormat0.format(0) : (settings.clientPhone.startsWith("+971") && selectPay == 3) ? Utils.numFormat0.format(0) : Utils.numFormat0.format(settings.itogCashbackSumm), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    Visibility(
                      visible: DataService.jumaName.isNotEmpty || DataService.jumaSavdoSumm != 0,
                      child: Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "${AppLocalizations.of(context).translate("cashback")} (${DataService.jumaName}):",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                              ),
                            ),
                            Text("${Utils.myNumFormat0(DataService.getJuma(settings.itogSumm, DataService.jumaSavdoSumm, DataService.jumaSumm).toDouble())} ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                      ),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Theme.of(context).primaryColor)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  AppLocalizations.of(context).translate("gl_back"),
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 6,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  fixedSize: Size(MediaQuery.of(context).size.width, 45),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: (){
                                  if(settings.clientPhone == "+998977406675"){
                                    sendOrder(settings);
                                    return;
                                  }
                                  if(selectPay == 0){
                                    showRedSnackBar(AppLocalizations.of(context).translate("inv_type"));
                                    return;
                                  }
                                  if(selectPay == 1 && deliveryDateController.text.isEmpty) {
                                    showRedSnackBar(AppLocalizations.of(context).translate("enter_delivery_date"));
                                    return;
                                  }
                                  if(selectPay == 3 && DataService.cashBack / settings.curRate < settings.itogSumm){
                                    showRedSnackBar(AppLocalizations.of(context).translate("lack_of_cashback"));
                                    return ;
                                  }
                                  if(selectPay == 4 && dateController.text.isEmpty) {
                                    showRedSnackBar(AppLocalizations.of(context).translate("enter_dolg_date"));
                                    return;
                                  }
                                  sendOrder(settings);
                                  settings.ordUuid = "";
                                },
                                child: Text(AppLocalizations.of(context).translate("gl_send"),
                                    style: TextStyle(color: Colors.white))),
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
      ),
    );
  }

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void paymeDialog(BuildContext context, MySettings settings) => showDialog(context: context, builder: (BuildContext context) => AlertDialog(
    titlePadding: EdgeInsets.zero,
    title: Stack(
      alignment: Alignment.topRight,
      children: [
        const Center(child: Image(image: AssetImage("assets/images/img.png"), width: 200)),
        IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.cancel)),
        const SizedBox(width: 10),
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
                    controller: paymeController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    autofocus: true,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(onPressed: (){
                        paymeController.clear();
                      }, icon: const Icon(Icons.close)),
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("enter_summ"),
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
                      if(paymeController.text.isEmpty){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      }else if(double.parse(paymeController.text) <= 1999){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_more_summ"));
                      } else{
                        await newPayme(settings);
                        await Share.share("Payme link: $paymeUrl");
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
                    backgroundColor: const Color.fromRGBO(99, 197, 201, 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: ()async{
                    if (paymeController.text.isEmpty){
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                    } else {
                      await newPayme(settings);
                      launchUrl(Uri.parse(paymeUrl), mode: LaunchMode.externalApplication);
                      paymeController.clear();
                      Navigator.pop(context);
                    }
                  }, child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).translate("dash_do_pay")),
                  const Icon(Icons.chevron_right),
                ],
              ))
          ),
        ],
      ),
    ],
  ));

  Future<void> newPayme(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-payme");
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
            "summ": Utils.checkDouble(paymeController.text),
          })
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("newPayme Error 1 data null or data['ok] != 1 !");
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
        debugPrint("newPayme Error 2 data null or data['ok] != 1 ");
      }
      return;
    }

    if (data["ok"] == 1) {
      paymeList = [NewPaymeModel.fromJson(data['d'])];
      debugPrint("new-payme: $paymeList");
      for (var paymeModel in paymeList) {
        paymeUrl = paymeModel.url;
      }
    }
  }

  void clickDialog(BuildContext context, MySettings settings) => showDialog(context: context, builder: (BuildContext context) => AlertDialog(
    title: Stack(
      alignment: Alignment.topRight,
      children: [
        const Center(child: Image(image: AssetImage("assets/images/click.png"), width: 200)),
        IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.cancel)),
        const SizedBox(width: 10),
      ],
    ),
    titlePadding: EdgeInsets.zero,
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
                    controller: clickController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    autofocus: true,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(onPressed: (){
                        clickController.clear();
                      }, icon: const Icon(Icons.close)),
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("enter_summ"),
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
                      if(clickController.text.isEmpty){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      }else if(double.parse(clickController.text) <= 1999){
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_more_summ"));
                      } else{
                        await newClick(settings);
                        await Share.share("Click link: $clickUrl");
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
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: ()async{
                    if(clickController.text.isEmpty){
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                    }else{
                      await newClick(settings);
                      launchUrl(Uri.parse(clickUrl), mode: LaunchMode.externalApplication);
                      clickController.clear();
                      Navigator.pop(context);
                    }
                  }, child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).translate("dash_do_pay")),
                  const Icon(Icons.chevron_right),
                ],
              ))
          ),
        ],
      ),
    ],
  ));

  Future<void> newClick(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-click");
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
            "summ": Utils.checkDouble(clickController.text),
          })
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("newClick Error 1 data null or data['ok] != 1 !");
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON: send_ord_page: 914")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        debugPrint("newClick Error 2 data null or data['ok] != 1 ");
      }
      return;
    }

    if (data["ok"] == 1) {
      DataService.newClick = [NewClickModel.fromJson(data['d'])];
      debugPrint("new-click: ${DataService.newClick}");
      for (var clickModel in DataService.newClick) {
        clickUrl = clickModel.url;
      }
    }
  }

  void networkPayDialog(BuildContext context, MySettings settings) => showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Stack(
          alignment: Alignment.topRight,
          children: [
            const Center(child: Image(image: AssetImage("assets/images/logo-network.png"), width: 250)),
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.cancel)),
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
                        controller: networkController,
                        keyboardType: const TextInputType.numberWithOptions(),
                        autofocus: true,
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: Colors.grey.shade200,
                          errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                          labelText: AppLocalizations.of(context).translate("enter_summ"),
                          focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                          border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          if (networkController.text.isEmpty) {
                            showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                          } else if (double.parse(networkController.text) <= 50) {
                            showRedSnackBar(AppLocalizations.of(context).translate("enter_more_summ"));
                          } else {
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
                        if (networkController.text.isEmpty) {
                          showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                          return;
                        }
                        Navigator.pop(context);
                        if(settings.doNotShowAgain == 1){
                          setState(() {
                            isSending = true;
                          });
                          await networkPayment(settings);
                          launchUrl(Uri.parse(networkUrl), mode: LaunchMode.externalApplication);
                          setState(() {
                            isSending = false;
                          });
                          networkController.clear();
                        }
                        _showSecurePaymentBottomSheet(context, settings);
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

  void _showSecurePaymentBottomSheet(BuildContext context, MySettings settings) {
    bool dontShowAgain = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(AppLocalizations.of(context).translate("payment_warning"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (value) {
                              setModalState(() {
                                dontShowAgain = value ?? false;
                                settings.doNotShowAgain = dontShowAgain ? 1 : 0;
                              });
                            },
                            activeColor: const Color.fromRGBO(40, 105, 172, 1),
                          ),
                          Text(AppLocalizations.of(context).translate("do_not_show_again"),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        "assets/images/ngenius_payment_warning.jpg",
                        fit: BoxFit.contain,
                        height: 350,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(40, 105, 172, 1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              isSending = true;
                            });
                            await networkPayment(settings);
                            launchUrl(Uri.parse(networkUrl), mode: LaunchMode.externalApplication);
                            setState(() {
                              isSending = false;
                            });
                            networkController.clear();
                          },
                          child: Text(AppLocalizations.of(context).translate("got_it"),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> networkPayment(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error parsing JSON: send_ord_page: 1078")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        debugPrint("Response error: data null or data['ok'] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      networkUrl = data['d']['_links']['payment']['href'];
      debugPrint("networkUrl $networkUrl");
    }
  }

  Future<void> _selectDate(BuildContext context, MySettings settings) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        date1 = pickedDate;
        dateController.text = Utils.myDateFormat(Utils.formatDDMMYYY, date1);
      });
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context, MySettings settings) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        deliveryDate = pickedDate;
        deliveryDateController.text = Utils.myDateFormat(Utils.formatDDMMYYY, deliveryDate);
      });
    }
  }

  bool shouldBeVisible(String contractDate) {
    try {
      DateTime parsedDate = DateFormat("dd.MM.yyyy").parse(contractDate);

      if (parsedDate.day > 25) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Error parsing Date: $e");
      return false;
    }
  }

  Future<void> payedOrder(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-payed-for-order");
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
          "phone": settings.clientPhone,
          "ord_uuid": settings.ordUuid,
        }),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error parsing JSON: paidOrder: 1179")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (kDebugMode) {
        debugPrint("Response error: data null or data['ok'] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      final List<dynamic> payedOrdData = data['d'] ?? [];
      payedOrders = payedOrdData.map((item) => PayedOrderModel.fromMapObject(item)).toList();
      for (int i = 0; i < payedOrders.length; i++) {
        totalSumm += payedOrders[i].summ;
      }
      if (mounted) {
        setState(() {
          _shimmer = false;
        });
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

  void sendOrder(MySettings settings) async {
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/send-order");
    Response res = await post(
      uri,
      headers: <String, String>{
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
        "itogVitrinaSumm": settings.itogVitrinaSumm,
        "myUuid": "",
        "payType": selectPay,
        "dolgDate": selectPay == 4 ? Utils.myDateFormat(Utils.formatYYYYMMdd, date1): "",
        "deliveryDate": selectPay == 1 ? Utils.myDateFormat(Utils.formatYYYYMMdd, deliveryDate): "",
        "dolgNotes": debtNotesController.text,
        "cashbackSumm": (settings.clientPhone.startsWith("+998") && selectPay != 1) ? 0.0 : (settings.clientPhone.startsWith("+971") && selectPay == 3) ? 0.0 : settings.itogCashbackSumm,
        "list": settings.cartList,
        "vitrina": settings.vitrinaList,
        "payedSumm": Utils.checkDouble(totalSumm / settings.curRate),
        "jumaCashback": Utils.checkDouble(DataService.getJuma(settings.itogSumm, DataService.jumaSavdoSumm, DataService.jumaSumm)),
        "dolgIs": widget.hasPromo == false || _isAksiyaChecked ? 0 : 1,
        "checkPromo": _isAksiyaChecked ? 1 : 0
      }),
    );
    if (res.statusCode != 200) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${res.statusCode}")),
        );
      }
      return;
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid JSON response: On send_ord_page: 1310")),
        );
      }
      return;
    }
    if (data["ok"] == 1) {
      settings.cartList.clear();
      settings.vitrinaList.clear();
      settings.saveAndNotify();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate("sent_ord"))),
        );
      }
      Navigator.pop(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate("error"))),
        );
      }
    }
    // } catch (e) {
    if (context.mounted) {
      // debugPrint("An error occured: $e");
    }
    // }
  }
}