import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      child: Scaffold(
        appBar: AppBar(
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
                    // logout(settings);
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
    );
  }

  Widget getBottomNavigationBar(MySettings settings) {
    return BottomNavigationBar(
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
              myNavbarContainer(0),
              const SizedBox(height: 10),
              Image.asset("assets/icons/akt_sverka.png", color: _tabIndex == 0 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_catalog"),
        ),

        BottomNavigationBarItem(
            icon: Column(
              children: [
                myNavbarContainer(1),
                const SizedBox(height: 10),
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
              myNavbarContainer(2),
              const SizedBox(height: 10),
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


  Widget getSearchBar(MySettings settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: TextField(
          controller: searchQueryController,
          autofocus: false,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(top: 6, left: 12, bottom: 10),
            hintText: AppLocalizations.of(context).translate("gl_search"),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: InkWell(
                onTap: () {
                  setState(() {
                    searchQueryController.text = "";
                  });
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: const Icon(Icons.clear)),
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1),
          onChanged: (value) {
            setState(() {});
          },
        ),
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
      debugPrint("$res");
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print("Mijoz HomePage getAll Error data null or data['ok] != 1");
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
        print("Mijoz HomePage getAll Error data null or data['ok] != 1");
      }
      return;
    }

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

      for(int i = 0; i < DataService.juma.length; i++){
        DataService.jumaName = DataService.juma[i].name;
        DataService.jumaSavdoSumm = DataService.juma[i].savdo_summ;
        DataService.jumaSumm = DataService.juma[i].summ;
      }
      DataService.grp = grp;
      DataService.prods = prods;
      for (int i = 0; i < grp.length; i++) {
        grp[i].prodCount = 0;
        for (int k = 0; k < prods.length; k++) {
          if (grp[i].id == prods[k].groupId&&prods[k].ostQty > 0) {
            grp[i].prodCount++;
          }
        }
      }
      DataService.cashBack = Utils.checkDouble(data['d']["settings"]["cashback"]);
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]);
      DataService.creditLimit = Utils.checkDouble(data['d']["settings"]["credit_limit"]);
      if(mounted){
        setState(() {
          _isLoading = false;
          _shimmer = false;
        });
      }

      settings.curRate = Utils.checkDouble(data['d']["settings"]["curRate"]);
      settings.clientId = Utils.checkDouble(data['d']["settings"]["clientId"]).toInt();
      settings.clientName = data['d']["settings"]["clientName"]??"";
      settings.clientFio = data['d']["settings"]["clientFio"]??"";
      settings.clientAddress = data['d']["settings"]["clientAddress"]??"";
      settings.baseName = data['d']["settings"]["baseName"]??"";
      settings.basePhone = data['d']["settings"]["basePhone"]??"";

      settings.firmInn = data['d']["settings"]["firmInn"]??"";
      settings.firmName = data['d']["settings"]["firmName"]??"";
      settings.firmAddress = data['d']["settings"]["firmAddress"]??"";
      settings.firmSchet = data['d']["settings"]["firmSchet"]??"";
      settings.firmBank = data['d']["settings"]["firmBank"]??"";
      settings.firmMfo = data['d']["settings"]["firmMfo"]??"";
      settings.contractNum = data['d']["settings"]["contractNum"]??"";
      settings.contractDate = data['d']["settings"]["contractDate"]??"";
      settings.today = data['d']["settings"]["today"]??"";
      settings.ttClass = data['d']["settings"]["ttClass"]??"";
      settings.minVersion = Utils.checkDouble(data['d']["settings"]["min_version"]).toInt();
      settings.payInfo = data['d']["settings"]["payInfo"]??"";
      settings.botToken = data['d']["settings"]["botToken"]??"";
      settings.botChatId = Utils.checkDouble(data['d']["settings"]["botChatId"]).toInt();

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
              return Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filteredProds[index].orderQty > 0 ? Colors.orange : Colors.grey.shade400,
                    ),
                    color: filteredProds[index].orderQty != 0
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.grey.shade50,
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Future.delayed(const Duration(milliseconds: 200), () async {
                          if (filteredProds[index].ostQty == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context).translate("lack_of_prods")),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade700,
                            ));
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MijozDetailPage(filteredProds[index], false),
                            ),
                          );
                          refreshCart(settings);
                        });
                      },
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MijozDetailPage(filteredProds[index], false),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: CachedNetworkImage(
                                imageUrl: filteredProds[index].picUrl,
                                errorWidget: (context, v, d) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: const DecorationImage(
                                        image: AssetImage("assets/images/no_image_red.jpg"),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                                height: 310,
                                width: 170,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
                            child: Text(
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              filteredProds[index].name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            child: Text(
                              "${AppLocalizations.of(context).translate("price")}: ${Utils.myNumFormat0(filteredProds[index].clientPrice)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
    if (settings.mijozPhone == "+998935550801" || settings.mijozName == "Director") {
      await noScreenshot.screenshotOn();
    } else {
      await noScreenshot.screenshotOff();
    }
  }
}

