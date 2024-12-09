import 'dart:async';
import 'dart:convert';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/dic_card.dart';
import 'package:flutter_djolis/models/dic_groups.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/notif.dart';
import 'package:flutter_djolis/screens/firebase_notifications/firebase_notification_page.dart';
import 'package:flutter_djolis/screens/home/cart_page.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/screens/home/profile_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../common/photo.dart';
import 'dashboard_page.dart';
import 'my_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchQueryController = TextEditingController();

  List<DicGroups> grp = [];
  List<DicProd> prods = [];

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
              ? Text(AppLocalizations.of(context).translate("home_dash"))
              : (_tabIndex == 1
              ? getSearchBar(settings)
              : (_tabIndex == 2
              ? Text(AppLocalizations.of(context).translate("home_card_app_bar"))
              : (_tabIndex == 3
              ? Text(AppLocalizations.of(context).translate("home_akt"))
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
                    icon: const Icon(CupertinoIcons.bell),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: _tabIndex == 4,
              child: IconButton(
                onPressed: () {
                  logout(settings);
                },
                icon: const Icon(Icons.logout_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
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
              getBody(settings),
               // _listTab == 1 ? getBody(settings) : getVitrinaList(settings),
              Padding(
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
                      indicatorSize: const Size.fromWidth(150),
                      borderWidth: 2,
                      customIconBuilder: (context, local, global) {
                        switch (local.value) {
                          case 1:
                            return Text(AppLocalizations.of(context).translate("home_toggle_order"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
                          case 2:
                            return Text(AppLocalizations.of(context).translate("vitrina"), style: TextStyle(color: Color.lerp(Colors.black, Colors.white, local.animationValue), fontWeight: FontWeight.w700),);
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
                      selectedIconScale: 1.2,
                      onChanged: (value) {
                        setState(() {
                          _listTab = value;
                        });
                      },
                    ),
                  ),
                  // child: Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //   children: [
                  //     const SizedBox(width: 20),
                  //     Material(
                  //       child: InkWell(
                  //         onTap: (){
                  //           Future.delayed(const Duration(milliseconds: 500));
                  //           setState(() {
                  //             _listTab = 0;
                  //           });
                  //         },
                  //         child: Container(
                  //           height: 40,
                  //           width: 100,
                  //           decoration: BoxDecoration(
                  //             color: Theme.of(context).primaryColor,
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           child: Padding(
                  //             padding: const EdgeInsets.only(left: 8, right: 8),
                  //             child: Center(child: Text(AppLocalizations.of(context).translate("home_toggle_order"), style: const TextStyle(color: Colors.white),)),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     Material(
                  //       child: InkWell(
                  //         onTap: (){
                  //           Future.delayed(const Duration(milliseconds: 500));
                  //           setState(() {
                  //             _listTab = 1;
                  //           });
                  //         },
                  //         child: Container(
                  //           height: 40,
                  //           width: 100,
                  //           decoration: BoxDecoration(
                  //             color: Theme.of(context).primaryColor,
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           child: Padding(
                  //             padding: const EdgeInsets.only(left: 8, right: 8),
                  //             child: Center(child: Text(AppLocalizations.of(context).translate("vitrina"), style: const TextStyle(color: Colors.white),)),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 20),
                  //   ],
                  // ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Visibility(
                    visible: _tabIndex == 0 && settings.itogSumm > 0,
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        color: Colors.grey.shade200,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${AppLocalizations.of(context).translate("gl_summa_ord")}  ${Utils.myNumFormat0(settings.itogSumm)} у.е", style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text("${AppLocalizations.of(context).translate("cashback")}  ${Utils.myNumFormat0(settings.itogCashbackSumm)} сум", style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.green, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text("${AppLocalizations.of(context).translate("sales_vitrina")}:  ${Utils.myNumFormat0(settings.itogVitrinaSumm)} у.е", style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            // Text(
                            //   "${AppLocalizations.of(context).translate("gl_summa")}: ${Utils.myNumFormat0(settings.itogSumm)}",
                            //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            //     fontWeight: FontWeight.w600,
                            //     color: Colors.white,
                            //   ),
                            // ),
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
                                padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate("home_card"),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color.fromRGBO(94, 36, 66, 1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Color.fromRGBO(94, 36, 66, 1),
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
      selectedLabelStyle: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w400),
      unselectedLabelStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w400),
      unselectedItemColor: Colors.black,
      selectedItemColor: Colors.red,
      currentIndex: _tabIndex,
      type: BottomNavigationBarType.fixed,

      onTap: (index) {
        if (_tabIndex == index) {
          if (index == 0) {
            return;
          }
          if (index == 1) {
            getCategoryList(settings);
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
              Image.asset("assets/icons/akt_sverka.png", color: _tabIndex == 0 ? Colors.red : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_dash"),
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(1),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/home_icon.png", color: _tabIndex == 1 ? Colors.red : Colors.black, height: 24,),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_catalog"),
        ),

        BottomNavigationBarItem(
            icon: Column(
              children: [
                myNavbarContainer(2),
                const SizedBox(height: 10,),
                Image.asset("assets/icons/shopping_bag.png", color: _tabIndex == 2 ? Colors.red : Colors.black, height: 24),
              ],
            ),
            label: AppLocalizations.of(context).translate("home_card")
        ),

        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(3),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/chat_icon.png", color: _tabIndex == 3 ? Colors.red : Colors.black, height: 24),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_akt"),
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              myNavbarContainer(4),
              const SizedBox(height: 10,),
              Image.asset("assets/icons/profile.png", color: _tabIndex == 4 ? Colors.red : Colors.black, height: 24),
            ],
          ),
          label: AppLocalizations.of(context).translate("home_profile"),
        ),
      ],
    );
  }

  Widget myNavbarContainer(int index) {
    return Container(
      height: 2,
      width: 110,
      color: _tabIndex == index ? Colors.red : Colors.grey.shade200,
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
            const SizedBox(height: 60),
            Expanded(
              child: _isLoading
                  ? Center(
                child: Container(
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
                ),
              ) : ListView.builder(
                key:  PageStorageKey<String>('controllerA'),
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
                                Future.delayed(Duration(milliseconds: 200), () {
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
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: EdgeInsets.fromLTRB(2, 2, 2, 12),
                    //height: (filteredProds[index].orderQty != 0 ? 140 : 110) + (filteredProds[index].info.isNotEmpty ? 18 : 0),
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
                          Future.delayed(Duration(milliseconds: 200), () async {
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
                                            Visibility(visible: filteredProds[index].cashbackSumm > 0, child: Text("( ${Utils.myNumFormat0(filteredProds[index].cashbackSumm)} )", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.green))),
                                            Visibility(visible: filteredProds[index].cashbackSumm > 0, child: SizedBox(width: 5)),
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
      return _selectedGroupId == 0 && searchQueryController.text == "" ? (_listTab == 1 ? getCategoryList(settings) : getVitrinaList(settings)) : getProdsList(settings);
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
      DataService.cards = (data['d']["cards"] as List?)?.map((item) => DicCardModel.fromMapObject(item)).toList() ?? [];
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
      DataService.debt = Utils.checkDouble(data['d']["settings"]["dolg"]) ;
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
      res = await post(
        uri,
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
    List<DicProd> filteredProds = prods.where((prod) => prod.hasVitrina == 1||prod.prevOstVitrina != 0||prod.ostVitrina != 0||prod.savdoVitrina != 0).toList();
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
            padding: EdgeInsets.fromLTRB(2, 2, 2, 12),
            //height: 120,
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
                  Future.delayed(Duration(milliseconds: 200), () async {
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

}

