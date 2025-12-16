import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: Container(
        decoration:  const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/back_wallpaper.png"),fit: BoxFit.fill)
        ),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // dark icons for light background
            systemNavigationBarColor: Colors.white, // navigation bar rangi
            systemNavigationBarIconBrightness: Brightness.dark, // navigation bar icons
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _tabIndex == 0 ? null : AppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: _tabIndex == 1
                  ? getSearchBar(settings)
                  : (_tabIndex == 2
                  ? Text(AppLocalizations.of(context).translate("home_card_app_bar"), style: const TextStyle(color: Colors.white))
                  : (_tabIndex == 3
                  ? Text(AppLocalizations.of(context).translate("home_akt"), style: const TextStyle(color: Colors.white))
                  : Text(AppLocalizations.of(context).translate("profile_info")))),
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
                    visible: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: getCategoryList(settings),
                    ),
                  ),
                  Visibility(
                    visible: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: getVitrinaList(settings),
                    ),
                  ),
                  Visibility(
                    visible: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: getClients(settings),
                    ),
                  ),
                  getBody(settings),
                  Visibility(
                    visible: settings.ttClass == "D",
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Visibility(
                        visible: _selectedGroupId == 0 && _tabIndex == 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 56,
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
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: AnimatedToggleSwitch.size(
                                  current: _listTab,
                                  values: const [1, 2],
                                  iconOpacity: 1,
                                  height: 48,
                                  indicatorSize: const Size.fromWidth(120),
                                  borderWidth: 0,
                                  customIconBuilder: (context, local, global) {
                                    final isSelected = local.animationValue > 0.5;
                                    switch (local.value) {
                                      case 1:
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(context).translate("home_toggle_order"),
                                              style: TextStyle(
                                                color: Color.lerp(
                                                  Colors.grey.shade700,
                                                  Colors.white,
                                                  local.animationValue,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        );
                                      case 2:
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(context).translate("clients"),
                                              style: TextStyle(
                                                color: Color.lerp(
                                                  Colors.grey.shade700,
                                                  Colors.white,
                                                  local.animationValue,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        );
                                      default:
                                        return const SizedBox.shrink();
                                    }
                                  },
                                  styleBuilder: (value) {
                                    return ToggleStyle(
                                      indicatorColor: const Color.fromRGBO(120, 46, 76, 1),
                                      indicatorGradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromRGBO(120, 46, 76, 1),
                                          Color.fromRGBO(140, 56, 90, 1),
                                        ],
                                      ),
                                      indicatorBorderRadius: BorderRadius.circular(12),
                                      indicatorBoxShadow: [
                                        BoxShadow(
                                          color: const Color.fromRGBO(120, 46, 76, 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      borderColor: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      backgroundColor: Colors.transparent,
                                    );
                                  },
                                  selectedIconScale: 1.0,
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
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Visibility(
                        visible: _tabIndex == 0 && settings.itogSumm > 0,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${AppLocalizations.of(context).translate("gl_summa_ord")}  ${Utils.myNumFormat0(settings.itogSumm)} ${settings.clientPhone.startsWith("+998") ? "у.е":"AED"}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text("${AppLocalizations.of(context).translate("cashback")}  ${Utils.myNumFormat0(settings.itogCashbackSumm)} ${settings.clientPhone.startsWith("+998") ? "у.е":"AED"}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Visibility(
                                        visible: DataService.jumaName.isNotEmpty || DataService.jumaSavdoSumm != 0,
                                          child: Text("${AppLocalizations.of(context).translate("cashback")} (${DataService.jumaName}) ${Utils.myNumFormat0(DataService.getJuma(settings.itogSumm, DataService.jumaSavdoSumm, DataService.jumaSumm).toDouble())} ${settings.clientPhone.startsWith("+998") ? "у.е":"AED"}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                ),
          
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _tabIndex = 2;
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context).translate("home_card"),
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue.shade300,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.shopping_cart_outlined,
                                                  color: Colors.blue.shade300,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
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
        ),
      ),
    );
  }

  Widget getBottomNavigationBar(MySettings settings) {
    return BottomNavigationBar(
      backgroundColor: Colors.transparent,
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
              // myNavbarContainer(0),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/akt_sverka.png", color: _tabIndex == 0 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_dash"),
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              const SizedBox(height: 10,),
              Image.asset("assets/icons/home_icon.png", color: _tabIndex == 1 ? Theme.of(context).primaryColor : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_catalog"),
        ),

        BottomNavigationBarItem(
            icon: Column(
              children: [
                const SizedBox(height: 10,),
                Badge(
                    smallSize: 1,
                    largeSize: 10,
                    backgroundColor: Theme.of(context).primaryColor,
                    label: Text(settings.cartList.length.toString()),
                    isLabelVisible: settings.cartList.isNotEmpty,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    child: Image.asset("assets/icons/shopping_bag.png", color: _tabIndex == 2 ? Theme.of(context).primaryColor : Colors.black, height: 24)),
              ],
            ),
            label: AppLocalizations.of(context).translate("home_card")
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              // myNavbarContainer(3),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/chat_icon.png", color: _tabIndex == 3 ? Theme.of(context).primaryColor : Colors.black, height: 24),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_akt"),
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              // myNavbarContainer(4),
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
        return;
      },
      child: Column(
        children: [
          settings.ttClass == "D"
              ? const SizedBox(height: 60)
              : const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey<String>('controllerA'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: grp.length + 1,
              itemBuilder: (context, index) {
                if (index == grp.length) {
                  return const SizedBox(height: 70);
                }

                if (grp[index].prodCount <= 0) return const SizedBox.shrink();

                final hasOrders = grp[index].orderSumm > 0;

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
                            colors: hasOrders
                                ? [
                              Colors.orange.withOpacity(0.15),
                              Colors.deepOrange.withOpacity(0.08),
                            ]
                                : [
                              Colors.white.withOpacity(0.7),
                              Colors.white.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasOrders
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: hasOrders
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 200), () {
                                setState(() {
                                  _selectedGroupId = grp[index].id;
                                  _selectedGroupName = grp[index].name;
                                });
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Left side - Icon container
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: hasOrders
                                            ? [
                                          Colors.orange.withOpacity(0.2),
                                          Colors.deepOrange.withOpacity(0.15),
                                        ]
                                            : [
                                          const Color.fromRGBO(120, 46, 76, 0.15),
                                          const Color.fromRGBO(120, 46, 76, 0.08),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.list,
                                      color: hasOrders
                                          ? Colors.orange.shade700
                                          : const Color.fromRGBO(120, 46, 76, 1),
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Right side - Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Category name
                                        Text(
                                          grp[index].name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade900,
                                            height: 1.3,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Bottom info row
                                        Row(
                                          children: [
                                            // Product count
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${grp[index].prodCount}",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const Spacer(),

                                            // Order sum (if exists)
                                            if (hasOrders)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.orange.shade400,
                                                      Colors.deepOrange.shade400,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.orange.withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.shopping_bag_outlined,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      Utils.myNumFormat0(grp[index].orderSumm),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getProdsList(MySettings settings) {
    List<DicProd> filteredProds = prods.where((prod) => prod.groupId == _selectedGroupId).toList();
    if (searchQueryController.text != "") {
      filteredProds = prods.where((prod) => prod.name.toLowerCase().contains(searchQueryController.text.toLowerCase())).toList();
    }

    return Column(
      children: [
        // Back button header with glassmorphic design
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGroupId = 0;
                        _selectedGroupName = "";
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.chevron_back,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _selectedGroupName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 36), // Balance for back button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Products list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 70),
            itemCount: filteredProds.length,
            itemBuilder: (context, index) {
              if (filteredProds[index].ostQty <= 0) {
                return const SizedBox.shrink();
              }

              final hasOrder = filteredProds[index].orderQty > 0;
              final hasPromo = filteredProds[index].hasPromo > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: hasOrder
                              ? [
                            Colors.orange.shade100,
                            Colors.orange.shade50,
                          ]
                              : [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasOrder
                              ? Colors.orange.withOpacity(0.6)
                              : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: hasOrder
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (filteredProds[index].ostQty == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context).translate("lack_of_prods"),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                              return;
                            }
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  filteredProds[index],
                                  false,
                                ),
                              ),
                            );
                            refreshCart(settings);
                          },
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PhotoPage(
                                              url: filteredProds[index].picUrl,
                                              title: filteredProds[index].name,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'product_${filteredProds[index].id}',
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: Colors.white.withOpacity(0.8),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: filteredProds[index].picUrl,
                                              fit: BoxFit.contain,
                                              errorWidget: (context, v, d) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    image: const DecorationImage(
                                                      image: AssetImage(
                                                        "assets/images/no_image_red.jpg",
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Product Name
                                          Text(
                                            filteredProds[index].name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Stock Status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: filteredProds[index].ostQty == 0
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: filteredProds[index].ostQty == 0
                                                    ? Colors.red.withOpacity(0.3)
                                                    : Colors.green.withOpacity(0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  filteredProds[index].ostQty == 0
                                                      ? Icons.cancel_outlined
                                                      : Icons.check_circle_outline,
                                                  size: 12,
                                                  color: filteredProds[index].ostQty == 0
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  filteredProds[index].ostQty == 0
                                                      ? AppLocalizations.of(context).translate("not_exist")
                                                      : AppLocalizations.of(context).translate("exist"),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: filteredProds[index].ostQty == 0
                                                        ? Colors.red
                                                        : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Price
                                          Row(
                                            children: [
                                              Text(
                                                AppLocalizations.of(context).translate("price"),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                Utils.myNumFormat0(filteredProds[index].price),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color.fromRGBO(120, 46, 76, 1),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Product Info (if exists)
                                          if (filteredProds[index].info.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              filteredProds[index].info,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],

                                          // Order Info (if exists)
                                          if (hasOrder) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.orange.shade100,
                                                    Colors.orange.shade50,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange.withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.shopping_cart_outlined,
                                                          size: 14,
                                                          color: Colors.orange.shade700,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          "${AppLocalizations.of(context).translate("order")}: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade700,
                                                          ),
                                                        ),
                                                        Text(
                                                          filteredProds[index].getOrderQty,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      if (filteredProds[index].cashbackSumm > 0) ...[
                                                        Icon(
                                                          Icons.card_giftcard,
                                                          size: 12,
                                                          color: Colors.green.shade700,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          Utils.myNumFormat0(
                                                            filteredProds[index].cashbackSumm,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.green.shade700,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                      ],
                                                      const Icon(
                                                        CupertinoIcons.money_dollar_circle,
                                                        size: 14,
                                                        color: Color.fromRGBO(120, 46, 76, 1),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        Utils.myNumFormat0(
                                                          filteredProds[index].orderSumm,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color.fromRGBO(120, 46, 76, 1),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Promo Badge (top right)
                              if (hasPromo)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.deepOrange.shade500,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_offer,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          filteredProds[index].promoName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
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
              );
            },
          ),
        ),
      ],
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
      debugPrint("getAll home: ${res.body}");
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print("getAll home 845: Error data null or data['ok] != 1");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON: getAll home ")));
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
        print("getAll home 869: Error data null or data['ok] != 1");
        print("DATA: $data");
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
      // settings.djolisPayType = data['d']["settings"]["djolisPayType"]??"";
      settings.djolisPayType = "IYB";
      debugPrint("DjolisPayType: ${settings.djolisPayType}");
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
      padding: const EdgeInsets.only(top: 58, right: 8, left: 8, bottom: 8),
      child: ListView.builder(
        itemCount: filteredProds.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.5),
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
                          child:Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Hero(
                              tag: 'product_${filteredProds[index].id}',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: filteredProds[index].picUrl,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, v, d) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: const DecorationImage(
                                            image: AssetImage(
                                              "assets/images/no_image_red.jpg",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  maxLines: 2,
                                  filteredProds[index].name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Text("${AppLocalizations.of(context).translate("price")}: ${Utils.myNumFormat0(filteredProds[index].clientPrice)}",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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
    if (settings.clientPhone == "+998935550801" || settings.clientPhone == "+971977406675" || settings.clientPhone == "+998977406675" || settings.clientPhone == "+971552620505") {
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

