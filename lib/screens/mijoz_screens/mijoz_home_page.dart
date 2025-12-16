import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/dic_card.dart';
import 'package:flutter_djolis/models/dic_groups.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/juma_model.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:flutter_djolis/screens/firebase_notifications/firebase_notification_page.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/news.dart';
import '../common/photo.dart';
import 'mijoz_cart_page.dart';
import 'mijoz_detail_page.dart';
import 'mijoz_profile_page.dart';

class MijozHomePage extends StatefulWidget {
  const MijozHomePage({super.key});

  @override
  State<MijozHomePage> createState() => _MijozHomePageState();
}

class _MijozHomePageState extends State<MijozHomePage> {
  final noScreenshot = NoScreenshot.instance;
  TextEditingController searchQueryController = TextEditingController();
  MoneyMaskedTextController priceController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: ' ', precision: 0);

  List<DicGroups> grp = [];
  List<DicProd> prods = [];
  List<JumaModel> juma = [];

  int _tabIndex = 0;
  int _selectedGroupId = 0;
  String _selectedGroupName = "";
  bool _shimmer = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      checkUserAndSetScreenshot(settings);
      getAll(settings);
      refreshCart(settings);
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_shimmer) {
          getAll(settings);
        } else {
          timer.cancel();
        }
      });
    });

  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    refreshCart(settings);
    return PopScope(
      canPop: _selectedGroupId == 0&&_tabIndex == 0,
      onPopInvoked: (v) async {
        if (_selectedGroupId != 0) {
          _selectedGroupId = 0;
          _selectedGroupName = "";
          setState(() {});
          return;
        }
        if (_tabIndex != 0) {
          _tabIndex = 0;
          setState(() {

          });
          return;
        }
      },
      child: Container(
        decoration:  const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/back_wallpaper.png"),fit: BoxFit.fill)
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: _tabIndex == 0 ? Text(AppLocalizations.of(context).translate("home_dash"), style: const TextStyle(color: Colors.white)) : (_tabIndex == 0 ? Text(AppLocalizations.of(context).translate("home_dash"), style: const TextStyle(color: Colors.white)) : (_tabIndex == 1 ? Text(AppLocalizations.of(context).translate("home_card_app_bar"), style: const TextStyle(color: Colors.white)) : Text(AppLocalizations.of(context).translate("profile_info")))),
            actions: [
              Visibility(
                visible: _tabIndex == 0 || _tabIndex == 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Badge(
                    label: Text(
                      DataService.notifs.where((v) => !v.has_read).length.toString(),
                    ),
                    isLabelVisible: DataService.notifs.where((v) => !v.has_read).isNotEmpty,
                    offset: const Offset(-4, 0),
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    largeSize: 20,
                    smallSize: 18,
                    backgroundColor: Colors.yellow,
                    textColor: Colors.red,
                    child: IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FirebaseNotificationPage(),
                          ),
                        );
                        setState(() {});
                      },
                      icon: const Icon(CupertinoIcons.bell, color: Colors.white,),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: settings.minVersion > MySettings.intVersion,
                child: IconButton(onPressed: (){
                  getAll(settings);
                }, icon: const Icon(Icons.sync)),
              ),
              Visibility(
                visible: _tabIndex == 2,
                child: IconButton(
                  onPressed: () async{
                    if (await confirm(
                      context,
                      title: Text("${AppLocalizations.of(context).translate("log_out")}?"),
                      content: Text(AppLocalizations.of(context).translate("confirm_log_out")),
                      textOK: Text(AppLocalizations.of(context).translate("gl_yes")),
                      textCancel: Text(AppLocalizations.of(context).translate("gl_no")),
                    )) {
                      settings.logout();
                      settings.cartList.clear();
                      settings.saveAndNotify();
                    }
                  },
                  icon: const Icon(Icons.logout_outlined),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () {
              return getAll(settings);

            },
            child: SafeArea(
              child: settings.minVersion > MySettings.intVersion ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(AppLocalizations.of(context).translate("app_update_warning"), textAlign: TextAlign.center,style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text("${AppLocalizations.of(context).translate("your_version")} ${MySettings.intVersion}", textAlign: TextAlign.center,style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text("${AppLocalizations.of(context).translate("required_min_version")} ${settings.minVersion}", textAlign: TextAlign.center,style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: (){
                    if(Platform.isIOS){
                      launchUrl(Uri.parse("https://apps.apple.com/us/app/djolis/id6736938912"));
                    }else{
                      launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=uz.merasoft.flutter_djolis&pcampaignid=web_share"));
                    }
                  }, child: Text(AppLocalizations.of(context).translate("update_app"))),
                ],
              ) :getBody(settings),
            ),
          ),
          bottomNavigationBar: getBottomNavigationBar(settings),
        ),
      ),
    );
  }

  Widget getBottomNavigationBar(MySettings settings) {
    return BottomNavigationBar(
      backgroundColor: Colors.white.withOpacity(0.7),
      elevation: 0,
      selectedLabelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.w400),
      unselectedLabelStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w400),
      unselectedItemColor: Colors.black,
      selectedItemColor: Theme.of(context).primaryColor,
      currentIndex: _tabIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (_tabIndex == index) {
          if (index == 0) {
            return;
          }
          if (index == 1) {
            return;
          }
          if (index == 2) {
            return;
          }
        }
        setState(() {
          _tabIndex = index;
        });
      },
      items: [

        BottomNavigationBarItem(
          icon: Column(
            children: [
              Image.asset("assets/icons/akt_sverka.png", color: _tabIndex == 0 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_catalog"),
        ),

        BottomNavigationBarItem(
            icon: Column(
              children: [
                Badge(
                    label: Text(
                      settings.cartList.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    isLabelVisible: settings.cartList.isNotEmpty,
                    child: Image.asset("assets/icons/shopping_bag.png", color: _tabIndex == 1 ? Theme.of(context).primaryColor : Colors.black, height: 24)),
              ],
            ),
            label: AppLocalizations.of(context).translate("home_card")
        ),
        
        BottomNavigationBarItem(
          icon: Column(
            children: [
              Image.asset("assets/icons/profile.png", color: _tabIndex == 2 ? Theme.of(context).primaryColor : Colors.black, height: 24),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_profile"),
        ),
      ],
    );
  }

  Widget myNavbarContainer(int index) {
    return Container(
      height: 4,
      width: 110,
      decoration: BoxDecoration(
        borderRadius:  BorderRadius.only(topLeft: Radius.circular(_tabIndex == index ? 8 : 0), topRight: Radius.circular(_tabIndex == index ? 8 : 0 )),
        color: _tabIndex == index ? Theme.of(context).primaryColor : Colors.grey.shade200,
      ),
    );
  }


  Widget getBody(MySettings settings) {
    if (_shimmer) return shimmerList(settings);
    if (_tabIndex == 0) return getClientsProdList(settings);
    if (_tabIndex == 1) return MijozCartPage(refreshCart);
    if (_tabIndex == 2) return MijozProfilePage(settings: settings);
    return const Text("");
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mijoz HomePage getAll Error")));
        debugPrint("Mijoz HomePage getAll Error data null or data['ok] != 1");
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error JSON")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      _isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Mijoz data null")));
      debugPrint("Mijoz HomePage getAll Error data null or data['ok] != 1");
      return;
    }


    try {
      if (data["ok"] == 1) {
        grp = (data['d']["groups"] as List?)?.map((item) => DicGroups.fromMapObject(item)).toList() ?? [];
        prods = (data['d']["prods"] as List?)?.map((item) => DicProd.fromMapObject(item)).toList() ?? [];
        DataService.notifs = (data['d']["notifs"] as List?)?.map((item) => NotifModel.fromMapObject(item)).toList() ?? [];
        DataService.newsList = (data['d']["news"] as List?)?.map((item) => NewsModel.fromMapObject(item)).toList() ?? [];
        DataService.cards = (data['d']["cards"] as List?)?.map((item) => DicCardModel.fromMapObject(item)).toList() ?? [];
        DataService.juma = (data['d']["juma"] as List?)?.map((item) => JumaModel.fromMapObject(item)).toList() ?? [];
        DataService.jumaName = "";
        DataService.jumaSavdoSumm = 0;
        DataService.jumaSumm = 0;

        for (int i = 0; i < DataService.juma.length; i++) {
          DataService.jumaName = DataService.juma[i].name;
          DataService.jumaSavdoSumm = DataService.juma[i].savdo_summ;
          DataService.jumaSumm = DataService.juma[i].summ;
        }
        DataService.grp = grp;
        DataService.prods = prods;
        for (int i = 0; i < grp.length; i++) {
          grp[i].prodCount = 0;
          for (int k = 0; k < prods.length; k++) {
            if (grp[i].id == prods[k].groupId && prods[k].ostQty > 0) {
              grp[i].prodCount++;
            }
          }
        }

        DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
        DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]);
        DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);

        settings.curRate = Utils.checkDouble(data['d']["settings"]["curRate"]);
        settings.clientId = Utils.checkDouble(data['d']["settings"]["clientId"]).toInt();
        settings.clientName = data['d']["settings"]["clientName"] ?? "";
        settings.clientFio = data['d']["settings"]["clientFio"] ?? "";
        settings.clientAddress = data['d']["settings"]["clientAddress"] ?? "";
        settings.baseName = data['d']["settings"]["baseName"] ?? "";
        settings.basePhone = data['d']["settings"]["basePhone"] ?? "";
        settings.firmInn = data['d']["settings"]["firmInn"] ?? "";
        settings.firmName = data['d']["settings"]["firmName"] ?? "";
        settings.firmAddress = data['d']["settings"]["firmAddress"] ?? "";
        settings.firmSchet = data['d']["settings"]["firmSchet"] ?? "";
        settings.firmBank = data['d']["settings"]["firmBank"] ?? "";
        settings.firmMfo = data['d']["settings"]["firmMfo"] ?? "";
        settings.contractNum = data['d']["settings"]["contractNum"] ?? "";
        settings.contractDate = data['d']["settings"]["contractDate"] ?? "";
        settings.today = data['d']["settings"]["today"] ?? "";
        settings.ttClass = data['d']["settings"]["ttClass"] ?? "";
        settings.minVersion = Utils.checkDouble(data['d']["settings"]["min_version"]).toInt();
        settings.payInfo = data['d']["settings"]["payInfo"] ?? "";
        settings.botToken = data['d']["settings"]["botToken"] ?? "";
        settings.botChatId = Utils.checkDouble(data['d']["settings"]["botChatId"]).toInt();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _shimmer = false;
          });
        }
      }
    } catch (e) {
      _isLoading = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error!")));
      }
    }
  }


  void refreshCart(MySettings settings) {
    for (var p in prods) {
      p.orderQty = 0;
      p.orderSumm = 0;
      p.cashbackSumm = 0;
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
          p.cashbackSumm += c.cashbackSumm;
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

  Widget shimmerList(MySettings settings) {
    return Column(
      children: [
        settings.ttClass == "D" ? const SizedBox(height: 60) : const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.7),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon container shimmer
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Content shimmer
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Title shimmer
                                    Container(
                                      height: 16,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Subtitle shimmer
                                    Container(
                                      height: 14,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Bottom info row shimmer
                                    Row(
                                      children: [
                                        Container(
                                          height: 28,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),

                                        const Spacer(),

                                        Container(
                                          height: 28,
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void logout(MySettings settings) async {
    String fcmToken = await Utils.getToken();

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-logout");
    Response? res;
    try {
      res = await post(uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "Authorization": "Bearer ${settings.token}",
        },
      );

      if (res.body.toString().contains('OK')) {
        settings.logout();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Mijoz HomePage logOut Error data null or data['ok] != 1");
      }
      return;
    }
  }

  Widget _buildNotFoundWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          Text("${AppLocalizations.of(context).translate("prod_not_found")} :(", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget getClientsProdList(MySettings settings) {
    List<DicProd> filteredProds = prods.where((prod) => prod.forClients == 1).toList();

    if (searchQueryController.text.isNotEmpty) {
      filteredProds = filteredProds.where(
              (prod) => prod.name.toLowerCase().contains(searchQueryController.text.toLowerCase())).toList();
    }

    return filteredProds.isEmpty
        ? _buildNotFoundWidget(context)
        : SingleChildScrollView(
      child: Column(
        children: [
          Visibility(
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: DataService.newsList[index].picUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProds.length,
            itemBuilder: (context, index) {
              final screenWidth = MediaQuery.of(context).size.width;
              final imageWidth = (screenWidth * 0.45).clamp(140.0, 170.0);
              final imageHeight = imageWidth * 1.82;
              final product = filteredProds[index];
              final hasOrder = product.orderQty > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity( 0.6),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        if (product.ostQty == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(AppLocalizations.of(context).translate("lack_of_prods")),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MijozDetailPage(product, false),
                          ),
                        );
                        refreshCart(settings);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Rasm qismi
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: imageHeight,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.7),
                                                Colors.white.withOpacity(0.6),
                                                Colors.white.withOpacity(0.5),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      CachedNetworkImage(
                                        imageUrl: product.picUrl,
                                        errorWidget: (context, v, d) {
                                          return Container(
                                            height: imageHeight,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              image: const DecorationImage(
                                                image: AssetImage("assets/images/no_image_red.jpg"),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          );
                                        },
                                        height: imageHeight,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                                      // Gradient overlay (rasm ustida yengil qorong'ulik)

                                    ],
                                  ),
                                ),
                              ),
                              // Badge agar mahsulot tanlangan bo'lsa
                              if (hasOrder)
                                Positioned(
                                  top: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${product.orderQty.toInt()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Stock badge
                              if (product.ostQty == 0)
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(AppLocalizations.of(context).translate("out_of_stock"), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ],
                          ),

                          // Ma'lumot qismi
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mahsulot nomi
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Narx va button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context).translate("price"),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            Utils.myNumFormat0(product.clientPrice),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Batafsil button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () async {
                                            await Navigator.push(context, MaterialPageRoute(builder: (context) => MijozDetailPage(product, false)));
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }


  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }
  void showSuccessSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  Future<void> checkUserAndSetScreenshot(MySettings settings) async {
    if (settings.mijozPhone == "+998935550801" || settings.mijozName == "Director" || settings.clientPhone == "+971552620505" || settings.mijozName == "Feruz" || settings.mijozName == "Akmaral") {
      await noScreenshot.screenshotOn();
    } else {
      await noScreenshot.screenshotOff();
    }
  }
}

