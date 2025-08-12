import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
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
import 'package:flutter_djolis/screens/home/cart_page.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/screens/home/profile_page/profile_page.dart';
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
import 'dashboard_page.dart';
import 'my_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final noScreenshot = NoScreenshot.instance;
  TextEditingController searchQueryController = TextEditingController();
  MoneyMaskedTextController priceController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: ' ', precision: 0);

  List<DicGroups> grp = [];
  List<DicProd> prods = [];
  List<JumaModel> juma = [];

  int _tabIndex = 0;
  int _selectedGroupId = 0;
  int _listTab = 1;
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
          title: _tabIndex == 0
              ? Text(AppLocalizations.of(context).translate("home_dash"), style: const TextStyle(color: Colors.white))
              : (_tabIndex == 1
              ? getSearchBar(settings)
              : (_tabIndex == 2
              ? Text(AppLocalizations.of(context).translate("home_card_app_bar"), style: const TextStyle(color: Colors.white))
              : (_tabIndex == 3
              ? Text(AppLocalizations.of(context).translate("home_akt"), style: const TextStyle(color: Colors.white))
              : Text(AppLocalizations.of(context).translate("profile_info"))))),
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
              visible: _tabIndex == 4,
              child: IconButton(
                onPressed: () async{
                  if (await confirm(
                    context,
                    title: Text("${AppLocalizations.of(context).translate("log_out")}?"),
                    content: Text(AppLocalizations.of(context).translate("confirm_log_out")),
                    textOK: Text(AppLocalizations.of(context).translate("gl_yes")),
                    textCancel: Text(AppLocalizations.of(context).translate("gl_no")),
                  )) {
                    logout(settings);
                  }
                },
                icon: const Icon(Icons.logout_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
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
          ) :Stack(
            alignment: Alignment.topCenter,
            children: [
              Visibility(
                visible: _tabIndex == 1 && _listTab == 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: getCategoryList(settings),
                ),
              ),
              Visibility(
                visible: _tabIndex == 1 && _listTab == 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: getVitrinaList(settings),
                ),
              ),
              Visibility(
                visible: _tabIndex == 1 && _listTab == 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: getClients(settings),
                ),
              ),
              getBody(settings),
              Visibility(
                visible: settings.ttClass == "D",
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Visibility(
                    visible: _selectedGroupId == 0 && _tabIndex == 1,
                    child: SizedBox(
                      height: 50,
                      child: AnimatedToggleSwitch.size(
                        current: _listTab,
                        values: const [1, 2],
                        iconOpacity: 1,
                        height: 60,
                        indicatorSize: const Size.fromWidth(110),
                        borderWidth: 2,
                        customIconBuilder: (context, local, global) {
                          switch (local.value) {
                            case 1:
                              return Text(AppLocalizations.of(context).translate("home_toggle_order"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700, fontSize: 14));
                            case 2:
                              return Text(AppLocalizations.of(context).translate("clients"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700, fontSize: 14));
                              default:
                              return const Text("");
                          }
                        },
                        style: ToggleStyle(
                          indicatorColor: Theme.of(context).primaryColor,
                          borderColor: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: Colors.transparent,
                        ),
                        selectedIconScale: 1.1,
                        onChanged: (value) {
                          setState(() {
                            _listTab = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Visibility(
                    visible: _tabIndex == 0 || _tabIndex == 1 && settings.itogSumm > 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${AppLocalizations.of(context).translate("gl_summa_ord")}  ${Utils.myNumFormat0(settings.itogSumm)} у.е", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text("${AppLocalizations.of(context).translate("cashback")}  ${Utils.myNumFormat0(settings.itogCashbackSumm)} у.е", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Visibility(
                                    visible: DataService.jumaName.isNotEmpty || DataService.jumaSavdoSumm != 0,
                                      child: Text("${AppLocalizations.of(context).translate("cashback")} (${DataService.jumaName}) ${Utils.myNumFormat0(DataService.getJuma(settings.itogSumm, DataService.jumaSavdoSumm, DataService.jumaSumm).toDouble())} у.е", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _tabIndex = 2;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB( 0, 8, 0, 8),
                                child: Row(
                                  children: [
                                    Text(AppLocalizations.of(context).translate("home_card"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
                                    const SizedBox(width: 2),
                                    Icon(Icons.shopping_cart_outlined, color: Theme.of(context).primaryColor),
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
            ],
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
            // getCategoryList(settings);
            return;
          }
          if (index == 2) {
            return;
          }
          if (index == 3) {
            return;
          }
          if (index == 4) {
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
              const SizedBox(height: 10,),
              Image.asset("assets/icons/akt_sverka.png", color: _tabIndex == 0 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_dash"),
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(1),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/home_icon.png", color: _tabIndex == 1 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_catalog"),
        ),

        BottomNavigationBarItem(
            icon: Column(
              children: [
                myNavbarContainer(2),
                const SizedBox(height: 10,),
                Image.asset("assets/icons/shopping_bag.png", color: _tabIndex == 2 ? Theme.of(context).primaryColor : Colors.black, height: 24),
              ],
            ),
            label: AppLocalizations.of(context).translate("home_card")
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(3),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/chat_icon.png", color: _tabIndex == 3 ? Theme.of(context).primaryColor : Colors.black, height: 24),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_akt"),
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(4),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/profile.png", color: _tabIndex == 4 ? Theme.of(context).primaryColor : Colors.black, height: 24),
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

  Widget getCategoryList(settings) {
    return RefreshIndicator(
      onRefresh: () async {
        getAll(settings);
        refreshCart(settings);
        return ;
      },
      child: Container(
        color: Colors.grey.shade200,
        child: Column(
          children: [
            settings.ttClass == "D" ? const SizedBox(height: 60) : const SizedBox(height: 10) ,
            Expanded(
              child: ListView.builder(
                key:  const PageStorageKey<String>('controllerA'),
                itemCount: grp.length + 1,
                itemBuilder: (context, index) {
                  if (index == grp.length) {
                    return const SizedBox(height: 70);
                  }
                  return Visibility(
                    visible: grp[index].prodCount > 0,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                        child: Container(
                          decoration: BoxDecoration(
                              //color: index % 2 == 0 ? (const Color(0xFFFFE9E8)) : null,
                            color: grp[index].orderSumm > 0 ? Colors.orange.shade50 : Colors.white,
                            border: Border.all(color: grp[index].orderSumm > 0 ? Colors.orange : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          height: 115,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  setState(() {
                                    _selectedGroupId = grp[index].id;
                                    _selectedGroupName = grp[index].name;
                                  });
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         SizedBox(
                                            height: 60,
                                            child: Text(grp[index].name,maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                                         ),
                                         Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.list_sharp, color: Colors.grey, size: 20,),
                                               const SizedBox(width: 5),
                                                Text("List: ${grp[index].prodCount}"),
                                              ],
                                            ),
                            
                                            Visibility(
                                              visible: grp[index].orderSumm > 0,
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Row(
                                                  children: [
                                                   const  Icon(CupertinoIcons.tags, size: 15),
                                                   const SizedBox(width: 5),
                                                    Text(Utils.myNumFormat0(grp[index].orderSumm), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                            
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                ],
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
        ),
      ),
    );
  }

  Widget getProdsList(MySettings settings) {
    List<DicProd> filteredProds = prods.where((prod) => prod.groupId == _selectedGroupId).toList();
    if (searchQueryController.text != "") {
      filteredProds = prods.where((prod) => prod.name.toLowerCase().contains(searchQueryController.text.toLowerCase())).toList();
    }
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              setState(() {
                _selectedGroupId = 0;
                _selectedGroupName = "";
              });
            },
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.chevron_back),
                  Expanded(child: Text(_selectedGroupName, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProds.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredProds.length) {
                  return const SizedBox(height: 70);
                }
                return Visibility(
                  visible: filteredProds[index].ostQty > 0,
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: filteredProds[index].orderQty > 0 ? Colors.orange : Colors.grey.shade300),
                          color: filteredProds[index].orderQty > 0 ? Colors.orange.shade50 : Colors.white
                          //color: index % 2 == 0 ? const Color(0xFFFFE9E8) : Colors.white,
                        ),
                        child: Material(
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
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(filteredProds[index], false)));
                                refreshCart(settings);
                              });
                            },
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(context,MaterialPageRoute(builder: (context) => PhotoPage(url: filteredProds[index].picUrl, title: filteredProds[index].name)),);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: CachedNetworkImage(imageUrl: filteredProds[index].picUrl, errorWidget: (context, v, d) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                image: const DecorationImage(image: AssetImage("assets/images/no_image_red.jpg"), fit: BoxFit.cover),
                                              ),
                                            );
                                          },
                                          height: 53,
                                          width: 54,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 5, right: 40),
                                            child: Text(
                                              maxLines: 2,
                                              filteredProds[index].name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 12, left: 8),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: filteredProds[index].ostQty == 0 ? Text(AppLocalizations.of(context).translate("not_exist"),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 12),
                                            ) : Text(AppLocalizations.of(context).translate("exist"),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            "${AppLocalizations.of(context).translate("price")}: ${Utils.myNumFormat0(filteredProds[index].price)}",
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Visibility(visible: filteredProds[index].info.isNotEmpty, child: Text(filteredProds[index].info, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red))),
                                      Visibility(visible: filteredProds[index].orderQty != 0, child: const SizedBox(height: 7)),
                                      Visibility(
                                        visible: filteredProds[index].orderQty != 0,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${AppLocalizations.of(context).translate("order")}: ${filteredProds[index].getOrderQty} ",
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700,),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(CupertinoIcons.tags, size: 15),
                                                const SizedBox(width: 5),
                                                Visibility(visible: filteredProds[index].cashbackSumm > 0, child: Text(Utils.myNumFormat0(filteredProds[index].cashbackSumm), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.green))),
                                                Visibility(visible: filteredProds[index].cashbackSumm > 0, child: const SizedBox(width: 5)),
                                                Text("${Utils.myNumFormat0(filteredProds[index].orderSumm)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Visibility(
                        visible: filteredProds[index].hasPromo > 0,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Container(
                              height: 25,
                              decoration:  BoxDecoration(
                                color: Colors.orange.shade300,
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                                child: Text(filteredProds[index].promoName, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getBody(MySettings settings) {
    if (_shimmer) return shimmerList(settings);
    if (settings.clientId == 0) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context).translate("client_not_assigned")),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _shimmer = true;
                });
                getAll(settings);
                Timer.periodic(const Duration(seconds: 5), (timer) {
                  if (_shimmer) {
                    getAll(settings);
                  } else {
                    timer.cancel();
                  }
                });
              },
              child: Text(AppLocalizations.of(context).translate("gl_refresh")))
        ],
      ));
    }
    if (_tabIndex == 0) return const DashboardPage();
    if (_tabIndex == 1) {
      // return _listTab == 2
      //     ? getClients(settings)
      //     : (_selectedGroupId == 0 && searchQueryController.text == ""
      //     ? (_listTab == 1 ? getCategoryList(settings) : getVitrinaList(settings))
      //     : getProdsList(settings));

      return _selectedGroupId == 0 && searchQueryController.text == "" ? (_listTab == 1 ? getCategoryList(settings) : getClients(settings)) : getProdsList(settings);
    }
    if (_tabIndex == 2) return CartPage(refreshCart);
    if (_tabIndex == 3) return const MyChatPage();
    if (_tabIndex == 4) return ProfilePage(settings: settings,);
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
      settings.allowedMijozCount = Utils.checkDouble(data['d']["settings"]["allowedMijozCount"]).toInt();
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

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/logout");
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
        print("Error data null or data['ok] != 1");
      }
      return;
    }
  }

  Widget getVitrinaList(MySettings settings) {
    List<DicProd> filteredProds = prods.where((prod) => prod.forVitrina == 1 && (prod.hasVitrina == 1||prod.prevOstVitrina != 0||prod.ostVitrina != 0||prod.savdoVitrina != 0)).toList();
    // List<DicProd> filteredProds = prods.where((prod) => prod.forVitrina == 1).toList();
    if (searchQueryController.text != "") {
      filteredProds = prods.where((prod) => prod.name.toLowerCase().contains(searchQueryController.text.toLowerCase())).toList();
    }
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.only(top: 58, right: 8, left: 8, bottom: 8),
      child: ListView.builder(
        itemCount: filteredProds.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredProds.length) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 60,
                decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: Color.fromRGBO(94, 36, 66, 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${AppLocalizations.of(context).translate("gl_summa")}: ${Utils.myNumFormat0(settings.itogVitrinaSumm)}", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: (){
                            setState(() {
                              _tabIndex = 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                            child: Row(
                              children: [
                                Text(AppLocalizations.of(context).translate("gl_send"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: const Color.fromRGBO(94, 36, 66, 1),)),
                                const SizedBox(width: 8),
                                const Icon(Icons.send, color: Color.fromRGBO(94, 36, 66, 1)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            );
            //return const SizedBox(height: 70);
          }
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: filteredProds[index].savdoVitrina != 0 ? Colors.orange : Colors.grey.shade300),
                color: filteredProds[index].savdoVitrina != 0 ? Colors.orange.shade50 : Colors.white
              //color: index % 2 == 0 ? const Color(0xFFFFE9E8) : Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Future.delayed(const Duration(milliseconds: 200), () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(filteredProds[index], true)));
                    refreshCart(settings);
                  });
                },
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoPage(url: filteredProds[index].picUrl, title: filteredProds[index].name)),);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: CachedNetworkImage(imageUrl: filteredProds[index].picUrl, errorWidget: (context, v, d) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(image: AssetImage("assets/images/no_image_red.jpg"), fit: BoxFit.cover),
                                ),
                              );
                            },
                              height: 53,
                              width: 54,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 5, right: 5),
                                child: Text(
                                  maxLines: 2,
                                  filteredProds[index].name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 8),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  "${AppLocalizations.of(context).translate("previous_ost")}: ${Utils.myNumFormat0(filteredProds[index].prevOstVitrina)} ",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500,),
                                ),
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate("price")}: ${Utils.myNumFormat0(filteredProds[index].price)}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Visibility(visible: filteredProds[index].info.isNotEmpty, child: Text(filteredProds[index].info, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red))),
                          Visibility(visible: filteredProds[index].savdoVitrina != 0||filteredProds[index].ostVitrina != 0, child: const SizedBox(height: 7)),
                          Visibility(
                            visible: filteredProds[index].savdoVitrina != 0||filteredProds[index].ostVitrina != 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.of(context).translate("left_qty")}: ${Utils.myNumFormat0(filteredProds[index].ostVitrina)} ",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500,),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.of(context).translate("sales")}: ${Utils.myNumFormat0(filteredProds[index].savdoVitrina)} ",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(CupertinoIcons.tags, size: 15),
                                    const SizedBox(width: 5),
                                    Text("${Utils.myNumFormat0(filteredProds[index].savdoVitrina * filteredProds[index].price)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget getClients(MySettings settings){
    List<DicProd> filteredProds = prods.where((prod) => prod.forClients == 1).toList();
    if (searchQueryController.text != "") {
      filteredProds = prods.where((prod) => prod.name.toLowerCase().contains(searchQueryController.text.toLowerCase())).toList();
    }
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.only(top: 58, right: 8, left: 8, bottom: 8),
      child: ListView.builder(
        itemCount: filteredProds.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: filteredProds[index].savdoVitrina != 0 ? Colors.orange : Colors.grey.shade300),
                color: filteredProds[index].savdoVitrina != 0 ? Colors.orange.shade50 : Colors.white
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Future.delayed(const Duration(milliseconds: 200), () async {
                     showDialog(context: context, builder: (BuildContext context) => changeClientPriceDialog(settings, context, filteredProds[index].clientMinPrice, filteredProds[index].id, filteredProds[index].name));
                    refreshCart(settings);
                  });
                },
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoPage(url: filteredProds[index].picUrl, title: filteredProds[index].name)),);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: CachedNetworkImage(imageUrl: filteredProds[index].picUrl, errorWidget: (context, v, d) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(image: AssetImage("assets/images/no_image_red.jpg"), fit: BoxFit.cover),
                                ),
                              );
                            },
                              height: 53,
                              width: 54,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 5, right: 5),
                                child: Text(
                                  maxLines: 2,
                                  filteredProds[index].name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 8),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  "",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500,),
                                ),
                              ),
                              Text("${AppLocalizations.of(context).translate("price")}: ${Utils.myNumFormat0(filteredProds[index].clientPrice)}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Visibility(visible: filteredProds[index].info.isNotEmpty, child: Text(filteredProds[index].info, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red))),
                          Visibility(visible: filteredProds[index].savdoVitrina != 0||filteredProds[index].ostVitrina != 0, child: const SizedBox(height: 7)),
                          Visibility(
                            visible: filteredProds[index].savdoVitrina != 0||filteredProds[index].ostVitrina != 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.of(context).translate("left_qty")}: ${Utils.myNumFormat0(filteredProds[index].ostVitrina)} ",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500,),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.of(context).translate("sales")}: ${Utils.myNumFormat0(filteredProds[index].savdoVitrina)} ",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.blue),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(CupertinoIcons.tags, size: 15),
                                    const SizedBox(width: 5),
                                    Text("${Utils.myNumFormat0(filteredProds[index].savdoVitrina * filteredProds[index].price)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  AlertDialog changeClientPriceDialog(MySettings settings, BuildContext context, double minPrice, int prodId, String prodName) {
    return AlertDialog(
                     title: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(AppLocalizations.of(context).translate("set_price")),
                         InkWell(
                             onTap: () {
                               Navigator.pop(context);
                             },
                             child: Icon(Icons.cancel)),
                       ],
                     ),
                     actions: [
                       Column(
                         children: [
                           Align(
                             alignment: Alignment.centerLeft,
                             child: Padding(
                               padding: const EdgeInsets.only(left: 15, right: 15),
                               child: Center(child: Text(prodName, style: const TextStyle(fontWeight: FontWeight.w500),)),
                             ),
                           ),
                           const SizedBox(height: 20),
                           Padding(
                             padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                             child: Row(
                               children: [
                                 Expanded(
                                   flex: 8,
                                   child: TextFormField(
                                     controller: priceController,
                                     keyboardType: const TextInputType.numberWithOptions(),
                                     autofocus: true,
                                     decoration: InputDecoration(
                                       suffixIcon: IconButton(onPressed: (){
                                         priceController.clear();
                                       }, icon: Icon(Icons.clear)),
                                       isDense: true,
                                       fillColor: Colors.grey.shade200,
                                       errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                                       labelText: AppLocalizations.of(context).translate("enter_price"),
                                       focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                                       focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                                       border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                                       enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           Padding(
                             padding: const EdgeInsets.only(left: 12, top: 12),
                             child: Row(
                               children: [
                                 const Icon(Icons.info_outline, color: Colors.red),
                                 const SizedBox(width: 10),
                                 Text("${AppLocalizations.of(context).translate("min_price")} ${Utils.myNumFormat0(minPrice)}", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w400),),
                               ],
                             ),
                           ),
                           Padding(
                               padding: const EdgeInsets.all(18),
                               child: ElevatedButton(
                                   style: ElevatedButton.styleFrom(
                                     fixedSize: Size(MediaQuery.of(context).size.width, 50),
                                     backgroundColor: Colors.blue.shade600,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                   ),
                                   onPressed: () async {
                                     if (priceController.text == "") {
                                       showRedSnackBar("${AppLocalizations.of(context).translate("price_error")}");
                                       return;
                                     }

                                     if (priceController.numberValue < minPrice) {
                                       showRedSnackBar("${AppLocalizations.of(context).translate("should_be_higher_than_min_price")}: ${Utils.myNumFormat0(minPrice)}");
                                       return;
                                     }
                                     await sendPrice(settings, prodId);
                                     priceController.clear();

                                   }, child: Text(AppLocalizations.of(context).translate("profile_save")))
                           ),
                         ],
                       ),
                     ],
                   );
  }

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }
  void showSuccessSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  Future<void> checkUserAndSetScreenshot(MySettings settings) async {
    if (settings.clientPhone == "+998935550801" || settings.clientPhone == "+971977406675" || settings.clientPhone == "+998977406675") {
      await noScreenshot.screenshotOn();
    } else {
      await noScreenshot.screenshotOff();
    }
  }


  Future<void> sendPrice(MySettings settings, int productId) async {
    String fcmToken = await Utils.getToken();
    final text = priceController.text.replaceAll(' ', '');
    final price = int.tryParse(text);

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/set-client-price");

    Response? res;
    res = await post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
      body: jsonEncode({
        "product_id": productId,
        "price": price,
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("price_success_changed"));
      getAll(settings);
      Navigator.pop(context);
    } else {
      debugPrint("Xatolik: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

}

// leading: IconButton(onPressed: (){}, icon: const Image(image: AssetImage("assets/images/gold_medal_mini.png"), width: 35,)).addStarMenu(
//   items: [
//     Column(
//       children: [
//         const SizedBox(height: 100),
//         Stack(
//           children: [
//              Padding(
//               padding: EdgeInsets.only(top: 250),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Container(
//                   height: 130,
//                     decoration: BoxDecoration(
//                       color: const Color.fromRGBO(215, 167, 57, 0.6),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Center(child: Text("Premium Gold Mijoz!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
//                           Text("Djolis kompaniyasining Gold ta'rifli mijozi!", textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
//                           Text("Sizga qo'shimcha 3% qo'shimcha cashback va ko'plab sovg'alar belgilandi.", textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
//                         ],
//                       ),
//                     )),
//               ),
//                                ),
//            const Center(child: const Image(image: AssetImage("assets/images/gold_medal_mini.png"), width: 170)),
//             Shimmer.fromColors(
//                 baseColor: Colors.transparent,
//                 highlightColor: Colors.white,
//             child: const Center(child: const Image(image: AssetImage("assets/images/gold_medal_mini.png"), width: 170))),
//           ],
//         ),
//       ],
//     ),
//
//   ],
//   params:  const StarMenuParameters(
//     backgroundParams: BackgroundParams(
//       animatedBackgroundColor: true,
//       animatedBlur: true,
//       sigmaX: 4,
//       sigmaY: 4,
//       backgroundColor: Colors.transparent,
//     ),
//     circleShapeParams: CircleShapeParams(radiusY: 280,),
//     openDurationMs: 1000,
//     rotateItemsAnimationAngle: 180,
//     shape: MenuShape.linear,
//
//   ),
//   onItemTapped: (index, controller) {
//     controller.closeMenu!();
//   },
// ),

