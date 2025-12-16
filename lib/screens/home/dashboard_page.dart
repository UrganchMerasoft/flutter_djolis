import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/new_click_model.dart';
import 'package:flutter_djolis/models/new_payme_model.dart';
import 'package:flutter_djolis/screens/home/pay_by_bank_card.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
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
  double foydaUtgan = 0.0;
  double foydaShu = 0.0;
  double foydaUtganCashback = 0.0;
  double foydaShuCashback = 0.0;

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
      child: Container(
        decoration:  const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/back_wallpaper.png"),fit: BoxFit.fill)
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(image: AssetImage("assets/images/djolis_logo.png"),width: 95),
                      ],
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 15),
              ),

              SliverToBoxAdapter(
                child: Visibility(
                  visible: DataService.newsList.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: CarouselSlider.builder(
                      itemCount: DataService.newsList.length,
                      itemBuilder: (context, index, realIndex) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.97,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                                imageUrl: DataService.newsList[index].picUrl, fit: BoxFit.cover),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: (MediaQuery.of(context).size.width * 0.97) * 0.27 + 16,
                        viewportFraction: 1.2,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                      ),
                    ),
                  ),
                ),
              ),

              /// InfoContainer
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Cashback Card - Glass Green
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.7),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 35,
                                offset: const Offset(0, 10),
                                spreadRadius: -3,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, -5),
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                height: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate("cashback"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF059669), // green-600
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(Utils.myNumFormat(Utils.numFormat0, DataService.cashBack.toDouble()),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF047857), // green-700
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.clientPhone.startsWith("+998") ? "у.е" : "AED",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(0xFF059669),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Pre-paid Card - Dynamic Glass Color
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final debt = DataService.debt.toDouble();

                            // Determine colors based on debt value
                            Color baseColor;
                            Color textColor;
                            Color numberColor;

                            if (debt < 0) {
                              // Negative debt - Green
                              baseColor = const Color(0xFF10B981); // green-500
                              textColor = const Color(0xFF059669); // green-600
                              numberColor = const Color(0xFF047857); // green-700
                            } else if (debt > 0) {
                              // Positive debt - Red
                              baseColor = const Color(0xFFEF4444); // red-500
                              textColor = const Color(0xFFDC2626); // red-600
                              numberColor = const Color(0xFFB91C1C); // red-700
                            } else {
                              // Zero debt - Gray
                              baseColor = const Color(0xFF6B7280); // gray-500
                              textColor = const Color(0xFF4B5563); // gray-600
                              numberColor = const Color(0xFF374151); // gray-700
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withOpacity(0.7),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 35,
                                    offset: const Offset(0, 10),
                                    spreadRadius: -3,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, -5),
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    height: 80,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          getDebtText(debt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: numberColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Flexible(
                                          child: Text(
                                            Utils.myNumFormat(Utils.numFormat0_00, debt.abs()),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: numberColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          settings.clientPhone.startsWith("+998") ? "у.е" : "AED",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Credit Limit Card - Glass Purple
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.7),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 35,
                                offset: const Offset(0, 10),
                                spreadRadius: -3,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, -5),
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                height: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate("credit_limit"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF6B21A8), // purple-800
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        Utils.myNumFormat(Utils.numFormat0, DataService.creditLimit.toDouble()),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED), // violet-600
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.clientPhone.startsWith("+998") ? "у.е" : "AED",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(0xFF6B21A8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// SizedBox height: 10
              SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),

              /// Profit text
              SliverToBoxAdapter(
                child: Visibility(
                  visible: settings.allowedMijozCount > 0 && (foydaShu != 0 || foydaUtgan != 0 || foydaShuCashback != 0 || foydaUtganCashback != 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate("profit"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Header last and this month
              SliverToBoxAdapter(
                child: Visibility(
                  visible: settings.allowedMijozCount > 0 && (foydaShu != 0 || foydaUtgan != 0 || foydaShuCashback != 0 || foydaUtganCashback != 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate("last_month"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 40),
                        Text(
                          AppLocalizations.of(context).translate("this_month"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),
                ),
              ),

              /// Patient Dashboard
              SliverToBoxAdapter(
                child: Visibility(
                  visible: settings.allowedMijozCount > 0 && (foydaShu != 0 || foydaUtgan != 0 || foydaShuCashback != 0 || foydaUtganCashback != 0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 12),
                        child: Row(
                          children: [
                            // O'tgan oy foyda
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 9, bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(AppLocalizations.of(context).translate("from_patient"),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${Utils.myNumFormat(Utils.numFormat0, foydaUtgan.toDouble())} ${settings.clientPhone.startsWith("+998") ? "UZS" : "AED"}",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Joriy oy foyda
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(AppLocalizations.of(context).translate("from_patient"),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${Utils.myNumFormat(Utils.numFormat0, foydaShu.toDouble())} ${settings.clientPhone.startsWith("+998") ? "UZS" : "AED"}",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// Cashback Dashboard
              SliverToBoxAdapter(
                child: Visibility(
                  visible: settings.allowedMijozCount > 0 && (foydaShu != 0 || foydaUtgan != 0 || foydaShuCashback != 0 || foydaUtganCashback != 0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 12),
                        child: Row(
                          children: [
                            // O'tgan oy foyda
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(AppLocalizations.of(context).translate("from_cashback"),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${Utils.myNumFormat(Utils.numFormat0, foydaUtganCashback.toDouble())} ${settings.clientPhone.startsWith("+998") ? "UZS" : "AED"}",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Joriy oy foyda
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(AppLocalizations.of(context).translate("from_cashback"),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${Utils.myNumFormat(Utils.numFormat0, foydaShuCashback.toDouble())} ${settings.clientPhone.startsWith("+998") ? "UZS" : "AED"}",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Visibility(
                  visible: settings.clientPhone != "+998977406675" && !settings.clientPhone.startsWith("+971"),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: settings.djolisPayType != "NONE",
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8, top: 0, bottom: 0),
                          child: SizedBox(
                              height: 20,
                              child:  Text(AppLocalizations.of(context).translate("dash_pay"), textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600, color: Color.fromRGBO(26, 58, 93, 1), fontSize: 14))),
                        ),
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
                            ],
                          )

                              : settings.djolisPayType == "NONE"
                              ? const SizedBox.shrink()

                              : settings.djolisPayType == "PAYME"
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                  onTap: () {
                                    paymeDialog(context, settings);
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
                                    clickDialog(context, settings);
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

                            ],
                          )   /// CLICK, PAYME chiqadi

                              : settings.djolisPayType == "IYB"
                              ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PayByBankCard()));
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    splashColor: Colors.white.withOpacity(0.1),
                                    highlightColor: Colors.white.withOpacity(0.05),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.white.withOpacity(0.4),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: isSending
                                          ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      )
                                          : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Card icon container
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.credit_card_rounded,
                                              color: Theme.of(context).primaryColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Text
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context).translate("card_payment"),
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).primaryColor,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text("Uzcard, Humo",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                          // Arrow
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Theme.of(context).primaryColor,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                              : const SizedBox.shrink()
                      ),

                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppLocalizations.of(context).translate("dash_info"),
                    style: const TextStyle(
                      color: Color.fromRGBO(26, 58, 93, 1),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              DataService.malumot.isEmpty
                  ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 12, bottom: 4),
                    child: Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 35,
                            offset: const Offset(0, 10),
                            spreadRadius: -3,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate("list_empty"),
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                    return DataService.malumot.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context).translate("list_empty")))
                        : Slidable(
                      key: ValueKey(DataService.malumot[index].id),
                      enabled: settings.clientPhone.startsWith("+971"),
                      endActionPane: ActionPane(
                        extentRatio: 0.3,
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              if (DataService.malumot[index].invoiceId > 0) {
                                await _downloadAndShareInvoicePDF(context, settings, DataService.malumot[index].invoiceId, DataService.malumot[index].id);
                                return;
                              }
                              if (DataService.malumot[index].paymentId > 0) {
                                await _downloadAndSharePaymentPDF(context, settings, DataService.malumot[index].paymentId,);
                                return;
                              }
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.share,
                            label: AppLocalizations.of(context).translate("gl_share"),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 35,
                              offset: const Offset(0, 10),
                              spreadRadius: -3,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, -5),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      DataService.malumot[index].getDocType(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          Utils.numFormat0_00.format(DataService.malumot[index].summ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                        if (settings.clientPhone.startsWith("+998"))
                                          Text(
                                            "${Utils.numFormat0.format(DataService.malumot[index].summ_uzs)} ${DataService.malumot[index].cur_name.toString()}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (DataService.malumot[index].getDocType(context) != "order" && DataService.malumot[index].mijozId != 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "${DataService.malumot[index].mijozId} ${DataService.malumot[index].mijozName}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (DataService.malumot[index].notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  DataService.malumot[index].notes,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    DataService.malumot[index].curtime_str,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: DataService.malumot.length + 1,
                ),
              )
            ],
          ),
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
                    const Icon(Icons.chevron_right),
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
                      settings.clientPhone.startsWith("+971") ? await networkPayment(settings) : await networkPaymentUz(settings);
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
        debugPrint("getDash Error 1 data null or data['ok] != 1");
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
        debugPrint("getDash 2 Error data null or data['ok] != 1");
      }
      return;
    }

    debugPrint("DATA: $data");
    if (data["ok"] == 1) {
      DataService.malumot = (data['d']["malumot"] as List?)?.map((item) => MalumotModel.fromMapObject(item)).toList() ?? [];
      DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]) ;
      DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);
      foydaUtgan = Utils.checkDouble(data['d']["settings"]["foyda_utgan"]);
      foydaShu = Utils.checkDouble(data['d']["settings"]["foyda_shu"]);
      foydaUtganCashback = Utils.checkDouble(data['d']["settings"]["foyda_cashback_utgan"]);
      foydaShuCashback = Utils.checkDouble(data['d']["settings"]["foyda_cashback_shu"]);

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
        print("getAll dash 983: Error data null or data['ok] != 1");
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
        print("getAll dash 1007: Error data null or data['ok] != 1");
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
          "mijoz_id": settings.mijozId,
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
            "mijoz_id": settings.mijozId,
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
          "mijoz_id": settings.mijozId,
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

  Future<void> networkPaymentUz(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius-uz");
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
            "mijoz_id": settings.mijozId,
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
      return Colors.green.shade600;
    }else if(checker > 0){
      return Colors.red.shade600;
    } else {
      return Colors.grey.shade800;
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

  Future<void> _downloadAndShareInvoicePDF(BuildContext context, MySettings settings, int invoiceId, int orderId) async {

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("wait"))));

    try {
      Uri uri = Uri.parse("http://37.230.115.134/telegram_bot_pdf/esale_dubai_invoice.php?inv_id=$invoiceId&order_id=$orderId");

      Response res = await get(uri);

      if (res.statusCode == 200) {

        final bytes = res.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/invoice_${invoiceId}_$orderId.pdf');
        await file.writeAsBytes(bytes);

        Rect? origin;
        if (context.mounted) {
          final renderBox = context.findRenderObject();
          if (renderBox is RenderBox) {
            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            if (size.width > 0 && size.height > 0) {
              origin = position & size;
            }
          }
        }

        // Agar origin null yoki nol bo'lsa, fallback qiymat berish
        // iOS 26 uchun MAJBURIY!
        origin ??= Rect.fromLTWH(0, 0, 100, 100);

        // PDF faylni share qilish
        final params = ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: origin,
        );

        final result = await SharePlus.instance.share(params);

        if (context.mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_shared_successfully"))));
          } else if (result.status == ShareResultStatus.dismissed) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("share_cancelled"))));
          } else {
            // ShareResultStatus.unavailable
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("share_unavailable")), backgroundColor: Colors.orange));
          }
        }
      } else {
        throw Exception('Failed to download PDF: ${res.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_download_error")), backgroundColor: Colors.red));
      }
      debugPrint("PDF download error: $e");
    }
  }

  Future<void> _downloadAndSharePaymentPDF(BuildContext context, MySettings settings, int paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("wait"))));

    try {
      // Yangi URL bilan to'g'ridan-to'g'ri PDF yuklab olish
      Uri uri = Uri.parse("http://37.230.115.134/telegram_bot_pdf/esale_dubai_payment.php?payment_id=$paymentId");

      Response res = await get(uri);  // POST o'rniga GET ishlatiladi

      if (res.statusCode == 200) {
        // PDF faylni vaqtinchalik saqlash
        final bytes = res.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/invoice_$paymentId.pdf');
        await file.writeAsBytes(bytes);

        // Context dan RenderBox olishga harakat qilish
        Rect? origin;
        if (context.mounted) {
          final renderBox = context.findRenderObject();
          if (renderBox is RenderBox) {
            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            // Faqat nol bo'lmagan o'lchamlar bo'lsa ishlatamiz
            if (size.width > 0 && size.height > 0) {
              origin = position & size;
            }
          }
        }

        // Agar origin null yoki nol bo'lsa, fallback qiymat berish
        // iOS 26 uchun MAJBURIY!
        origin ??= Rect.fromLTWH(0, 0, 100, 100);

        // PDF faylni share qilish
        final params = ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: origin,
        );

        final result = await SharePlus.instance.share(params);

        if (context.mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_shared_successfully"))));
          } else if (result.status == ShareResultStatus.dismissed) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("share_cancelled"))));
          } else {
            // ShareResultStatus.unavailable
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("share_unavailable")), backgroundColor: Colors.orange));
          }
        }
      } else {
        throw Exception('Failed to download PDF: ${res.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_download_error")), backgroundColor: Colors.red));
      }
      debugPrint("PDF download error: $e");
    }
  }

}


//     Row(
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