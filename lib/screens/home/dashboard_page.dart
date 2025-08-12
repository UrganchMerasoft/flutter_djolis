import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/new_click_model.dart';
import 'package:flutter_djolis/models/new_payme_model.dart';
import 'package:flutter_djolis/screens/home/pay_by_bank_card.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_localizations.dart';
import '../../../core/mysettings.dart';
import '../../../models/malumot_model.dart';
import '../../../services/data_service.dart';
import '../../../services/utils.dart';
import '../../models/bank_cards_model.dart';
import '../../models/dic_groups.dart';
import '../../models/dic_prod.dart';
import '../../models/juma_model.dart';
import '../../models/news.dart';
import '../../models/notif.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _shimmer = true;
  bool _isLoading = false;
  String clickUrl = "";
  String paymeUrl = "";
  String networkUrl = "";
  List<NewPaymeModel> paymeList = [];
  List<DicGroups> grp = [];
  List<DicProd> prods = [];
  List<BankCardsModel> bankCards = [];
  bool isSending = false;

  TextEditingController clickController = TextEditingController();
  TextEditingController paymeController = TextEditingController();
  TextEditingController networkController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController cashController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  late DateTime date1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getDash(settings);
      getAll(settings);
      refreshCart(settings);
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_shimmer) {
          getDash(settings);
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return RefreshIndicator(
      onRefresh: () async {
        getDash(settings);
        getAll(settings);
        refreshCart(settings);
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Visibility(
                visible: DataService.newsList.isNotEmpty,
                child: SizedBox(
                  height: (MediaQuery.of(context).size.width * 0.97) * 0.3 + 24,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                    child: ListView.builder(
                      itemCount: DataService.newsList.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            // openNews(DataService.newsList[index]);
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.97,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // width: 300,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: DataService.newsList[index].picUrl, fit: BoxFit.cover))),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                child: Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InfoContainer(
                          text1: AppLocalizations.of(context).translate("cashback"),
                          text2: Utils.myNumFormat(Utils.numFormat0, DataService.cashBack.toDouble()),
                          text3: "у.е",
                          color: Colors.green
                      ),
                      const SizedBox(width: 10),
                      InfoContainer(
                        text1: getDebtText(DataService.debt.toDouble()),
                        text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.debt.toDouble().abs()),
                        text3: "у.е",
                        color: getColor(DataService.debt.toDouble()),
                      ),
                      const SizedBox(width: 10),
                      InfoContainer(
                          text1: AppLocalizations.of(context).translate("credit_limit"),
                          text2: Utils.myNumFormat(Utils.numFormat0, DataService.creditLimit.toDouble()),
                          text3: "у.е"
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Visibility(
                visible: settings.clientPhone != "+998977406675",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 0),
                      child: Container(
                        height: 20,
                        child:  Text(AppLocalizations.of(context).translate("dash_pay"), textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 17))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: settings.clientPhone.startsWith("+971")
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              networkPayDialog(context, settings);
                            },
                            child: Container(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              height: 100,
                              width: 170,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                                    child: Center(child: isSending ? const CircularProgressIndicator() : const Image(image: AssetImage("assets/images/visa_card.png"), height: 70)),
                                  ),
                                  isSending ? Text(AppLocalizations.of(context).translate("wait")): Text(AppLocalizations.of(context).translate("card_payment"), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                                ],
                              ),
                            )
                          ),

                          InkWell(
                            onTap: () {
                              cashDialog(context, settings);
                            },
                            child: Container(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              height: 100,
                              width: 170,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(0, 2, 0, 0),
                                    child: Center(child: Image(image: AssetImage("assets/icons/money.png"), height: 70,)),
                                  ),
                                  Text(AppLocalizations.of(context).translate("cash_payment"), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                                ],
                              ),
                            )
                          ),

                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PayByBankCard()));
                                },
                                child: Container(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  height: 115,
                                  width: 150,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                                        child: Center(child: isSending ? const CircularProgressIndicator() : const Image(image: AssetImage("assets/images/credit_card_design.png"), height: 90,)),
                                      ),
                                      isSending ? Text(AppLocalizations.of(context).translate("wait")): Text(AppLocalizations.of(context).translate("card_payment"), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                )
                            ),
                          ),

                          const SizedBox(width: 10),

                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                                onTap: () {
                                  cashDialog(context, settings);
                                },
                                child: Container(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  height: 115,
                                  width: 150,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(2, 0, 2, 2),
                                        child: Center(child: Image(image: AssetImage("assets/images/wallet.png"), height: 90,)),
                                      ),
                                      Text(AppLocalizations.of(context).translate("cash_payment"), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                )
                            ),
                          ),


                        ],
                      )
                    ),

                  ],
                ),
              ),
            ),



            SliverToBoxAdapter(
              child: Visibility(
                visible: DataService.malumot.isEmpty,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 0),
                  child: Container(
                      height: 20,
                      child:  Text(AppLocalizations.of(context).translate("dash_info"), textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 17))),
                ),
              ),
            ),

            DataService.malumot.isEmpty
                ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate("list_empty"),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            )
                : SliverList(
                key: const PageStorageKey<String>('controllerA'),
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index == DataService.malumot.length) {
                        return const SizedBox(height: 70);
                      }
                  return DataService.malumot.isEmpty ? Center(child: Text(AppLocalizations.of(context).translate("list_empty")),) :Container(
                    margin: const EdgeInsets.all(8),

                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 10 ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DataService.malumot[index].getDocType(context), style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
                                Visibility(
                                  visible: DataService.malumot[index].getDocType(context) != "order" && DataService.malumot[index].mijozId != 0,
                                    child: Text("${DataService.malumot[index].mijozId} ${DataService.malumot[index].mijozName}", style: Theme.of(context).textTheme.bodySmall)),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(Utils.numFormat0_00.format(DataService.malumot[index].summ), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue)),
                                    const SizedBox(height: 2),
                                    Visibility(
                                      visible: settings.clientPhone.startsWith("+998"),
                                        child: Text("${Utils.numFormat0.format(DataService.malumot[index].summ_uzs)} ${DataService.malumot[index].cur_name.toString()}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey))),
                                  ],
                                )
                              ],
                            ),
                           const SizedBox(height: 4),
                           Visibility(
                              visible: DataService.malumot[index].notes.isNotEmpty,
                              child: Text(DataService.malumot[index].notes, maxLines: 2),
                            ),
                            Row(
                              children: [
                                const Expanded(child: Text("")),
                                Text(DataService.malumot[index].curtime_str, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
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
      ),
    );
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
                    Icon(Icons.chevron_right),
                  ],
                ))
          ),
        ],
      ),
    ],
  ));

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
                    controller: networkController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    // autofocus: true,
                    decoration: InputDecoration(
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
                    backgroundColor: isSending ? Colors.grey : const Color.fromRGBO(40, 105, 172, 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (isSending) {
                      return;
                    }
                    Navigator.pop(context);
                    setState(() {
                      isSending = true;
                    });
                    if (networkController.text.isEmpty){
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      isSending = false;
                    } else {
                      await networkPayment(settings);
                      launchUrl(Uri.parse(networkUrl), mode: LaunchMode.externalApplication);
                      isSending = false;
                      networkController.clear();
                    }
                  }, child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).translate("dash_do_pay")),
                  const Icon(Icons.chevron_right),
                ],
              )),
          ),

        ],
      ),
    ],
  ));

  void cashDialog(BuildContext context, MySettings settings) => showDialog(context: context, builder: (BuildContext context) => AlertDialog(
    titlePadding: const EdgeInsets.only(top: 15, right: 5),
    title: Stack(
      alignment: Alignment.centerRight,
      children: [
        Center(child: Text(AppLocalizations.of(context).translate("cash_payment"))),
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
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: TextFormField(
              controller: dateController,
              readOnly: true,
              onTap: () async{
                await _selectDate(context, settings);
              },
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.calendar_month),
                isDense: true,
                fillColor: Colors.grey.shade200,
                errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                labelText: AppLocalizations.of(context).translate("enter_date"),
                focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: TextFormField(
              controller: cashController,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.money),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.note_alt_sharp),
                isDense: true,
                fillColor: Colors.grey.shade200,
                errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                labelText: AppLocalizations.of(context).translate("akt_sverka_notes"),
                focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: ()async{
                    if (cashController.text.isEmpty){
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                    } else if(dateController.text.isEmpty){
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_date"));
                    } else {
                      await newCashPay(settings);
                      dateController.clear();
                      cashController.clear();
                      notesController.clear();
                      Navigator.pop(context);
                    }
                  }, child: Text(AppLocalizations.of(context).translate("dash_do_pay")))
          ),
        ],
      ),
    ],
  ));

  Future<void> getDash(MySettings settings) async {
    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-dash");
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

    debugPrint("DATA: $data");
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
      debugPrint("$res");
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

    if (data["ok"] == 1) {
      DataService.notifs = (data['d']["notifs"] as List?)?.map((item) => NotifModel.fromMapObject(item)).toList() ?? [];
      DataService.newsList = (data['d']["news"] as List?)?.map((item) => NewsModel.fromMapObject(item)).toList() ?? [];
      DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]);
      DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);
      DataService.juma = (data['d']["juma"] as List?)?.map((item) => JumaModel.fromMapObject(item)).toList() ?? [];

      DataService.jumaName = "";
      DataService.jumaSavdoSumm = 0;
      DataService.jumaSumm = 0;

      for(int i = 0; i < DataService.juma.length; i++){
        DataService.jumaName = DataService.juma[i].name;
        DataService.jumaSavdoSumm = DataService.juma[i].savdo_summ;
        DataService.jumaSumm = DataService.juma[i].summ;
      }
      if(mounted){
        setState(() {
          _isLoading = false;
          _shimmer = false;
        });
      }
    }
  }

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
          "summ": double.parse(clickController.text),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
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
            "summ": double.parse(paymeController.text),
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
          "summ": double.parse(networkController.text),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error parsing JSON: $e")));
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

  Future<void> newCashPay(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-pay");
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
            "curdate_mysql": Utils.myDateFormat(Utils.formatYYYYMMdd, date1),
            "client_id": settings.clientId,
            "summ": Utils.checkDouble(cashController.text),
            "notes": notesController.text
          })
      );
      print("Res\n\n\n${res.body}\n\n\n");
    } catch (e) {
      if (kDebugMode) {
        debugPrint("\n\n\nnewCashPay Error 1 data null or data['ok'] != 1 !\n\n\n");
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
        debugPrint("\n\n\nnewCashPay Error 2 data null or data['ok'] != 1\n\n\n");
      }
      return;
    }

    if (data["ok"] == 1) {
     debugPrint("\n\n\nnew-pay ok = 1 success!\n\n\n");
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

  void refreshCart(MySettings settings) {
    for (var p in prods) {
      p.orderQty = 0;
      p.orderSumm = 0;
      p.ostVitrina = 0;
      p.savdoVitrina = 0;
      p.savdoVitrinaSumm = 0;
    }
    for (var g in grp) {
      g.orderSumm = 0.0;
    }

    for (var c in settings.cartList) {
      for (var p in prods) {
        if (p.id == c.prodId) {
          c.prod = p;
          p.orderQty += c.qty;
          p.orderSumm += c.summ;
        }
      }
    }
    for (var c in settings.cartList) {
      for (var g in grp) {
        if (g.id == c.prod!.groupId) {
          g.orderSumm += c.summ;
        }
      }
    }


    for (var c in settings.vitrinaList) {
      for (var p in prods) {
        if (p.id == c.prodId) {
          c.prod = p;
          p.ostVitrina += c.ost;
          p.savdoVitrina += c.qty;
          p.savdoVitrinaSumm += c.summ;
        }
      }
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

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  Color getColor(double checker){
    if(checker < 0){
      return Colors.green;
    }else if(checker > 0){
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  String getDebtText(double checker){
    if(checker < 0){
      return AppLocalizations.of(context).translate("pre_paid");
    }else if(checker > 0){
      return AppLocalizations.of(context).translate("debt");
    } else{
      return AppLocalizations.of(context).translate("balance");
    }
  }

}

class InfoContainer extends StatelessWidget {
  final String text1;
  final String text2;
  final String text3;
  final Color? color;
  const InfoContainer({
    super.key,required this.text1, required this.text2, required this.text3, this.color
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Text(text1, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w200, fontSize: 13)),
            ),
            const SizedBox(height: 4),
            Text(text2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: color)),
            Text(text3, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


//     :Row(
//   mainAxisAlignment: MainAxisAlignment.spaceAround,
//   children: [
//     InkWell(
//         onTap: () {
//           paymeDialog(context, settings);
//         },
//         child: Container(
//           clipBehavior: Clip.antiAliasWithSaveLayer,
//           height: 70,
//           width: 110,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.all(Radius.circular(10)),
//           ),
//           child: const Image(image: AssetImage("assets/images/img.png")),
//         )
//     ),
//
//     InkWell(
//         onTap: () {
//           clickDialog(context, settings);
//         },
//         child:  Container(
//           clipBehavior: Clip.antiAliasWithSaveLayer,
//           height: 70,
//           width: 110,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.all(Radius.circular(10)),
//           ),
//           child: const Image(image: AssetImage("assets/images/click.png")),
//         )
//     ),
//
//     InkWell(
//         onTap: () {
//           cashDialog(context, settings);
//         },
//         child:  Container(
//           height: 70,
//           width: 110,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.all(Radius.circular(10)),
//           ),
//           child: const Padding(
//             padding: EdgeInsets.all(16),
//             child: Image(image: AssetImage("assets/images/salary.png")),
//           ),
//         )
//     ),
//   ],
// ),