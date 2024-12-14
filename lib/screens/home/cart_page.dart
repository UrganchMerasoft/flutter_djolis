import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/vitrina.dart';
import 'package:flutter_djolis/screens/home/send_ord_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';
import '../../models/dic_prod.dart';
import '../common/photo.dart';

class CartPage extends StatefulWidget {
  final Function refreshCart;
  const CartPage(this.refreshCart, {super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<DicProd> filteredProds = DataService.prods.where((prod) => prod.hasVitrina == 1 || prod.prevOstVitrina != 0 || prod.ostVitrina != 0 || prod.savdoVitrina != 0).toList();


  //TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).translate("home_toggle_order"), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),),
                      SizedBox(width: 16),
                      Text("( ${AppLocalizations.of(context).translate("cashback")} )", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.green),)
                    ],
                  ))),
            ),
          ),

          settings.cartList.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                child: Container(
                  height: 80,
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
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  height: 120,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Slidable(
                    endActionPane: ActionPane(
                      extentRatio: 0.20,
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: Icons.restore_from_trash_outlined,
                          onPressed: (BuildContext context1) async {
                            Future.delayed(const Duration(milliseconds: 200), () async {
                              deleteCart(settings, settings.cartList[index], index);
                            });
                          },
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: InkWell(
                        onTap: () async {
                          Future.delayed(const Duration(milliseconds: 300));
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(settings.cartList[index].prod!, false)));
                          widget.refreshCart(settings);
                        },
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoPage(url: settings.cartList[index].prod!.picUrl, title: settings.cartList[index].prod!.name)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: CachedNetworkImage(
                                      imageUrl: settings.cartList[index].prod!.picUrl,
                                      errorWidget: (context, v, d) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            image: const DecorationImage(image: AssetImage("assets/images/no_image_red.jpg"), fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                      height: 60,
                                      width: 55,
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
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Text(
                                            maxLines: 2,
                                            settings.cartList[index].prod!.name,
                                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text("${AppLocalizations.of(context).translate("order")}: ${Utils.myNumFormat0(settings.cartList[index].qty)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      Expanded(child: Text("  x  ${Utils.myNumFormat0(settings.cartList[index].price)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500))),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 5),
                                          Visibility(visible: settings.cartList[index].cashbackSumm > 0, child: Text("( ${Utils.myNumFormat0(settings.cartList[index].cashbackSumm)} )", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.green))),
                                          Visibility(visible: settings.cartList[index].cashbackSumm > 0, child: SizedBox(width: 5)),
                                          Text(Utils.myNumFormat0(settings.cartList[index].summ), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                                        ],
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
              childCount: settings.cartList.length,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Theme
                        .of(context)
                        .primaryColor,
                  ),
                  child: Center(child: Text(AppLocalizations.of(context).translate("vitrina"), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),))),
            ),
          ),

          settings.vitrinaList.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                child: Container(
                  height: 80,
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
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  height: 120,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Slidable(
                    endActionPane: ActionPane(
                      extentRatio: 0.20,
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: Icons.restore_from_trash_outlined,
                          onPressed: (BuildContext context1) async {
                            Future.delayed(const Duration(milliseconds: 200), () async {
                              deleteVitrinaList(settings, settings.vitrinaList[index], index);
                            });
                          },
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: InkWell(
                        onTap: () async {
                          Future.delayed(const Duration(milliseconds: 300));
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(settings.vitrinaList[index].prod!, false)));
                          widget.refreshCart(settings);
                        },
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context, MaterialPageRoute(builder: (context) => PhotoPage(url: settings.vitrinaList[index].prod!.picUrl, title: settings.cartList[index].prod!.name)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: CachedNetworkImage(
                                      imageUrl: settings.vitrinaList[index].prod!.picUrl,
                                      errorWidget: (context, v, d) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            image: const DecorationImage(image: AssetImage("assets/images/no_image_red.jpg"), fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                      height: 60,
                                      width: 55,
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
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Text(
                                            maxLines: 2,
                                            settings.vitrinaList[index].prod!.name,
                                            style: Theme
                                                .of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(fontSize: 16)
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text("${AppLocalizations.of(context).translate("order")}: ${Utils.myNumFormat0(settings.vitrinaList[index].qty)}", style: Theme
                                          .of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w700)),
                                      Expanded(child: Text("  x  ${Utils.myNumFormat0(settings.vitrinaList[index].price)}", style: Theme
                                          .of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500))),
                                      Row(
                                        children: [
                                          const Icon(CupertinoIcons.tags, size: 15),
                                          const SizedBox(width: 5),
                                          Text(Utils.myNumFormat0(settings.vitrinaList[index].summ), style: Theme
                                              .of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w700)),
                                        ],
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
              childCount: settings.vitrinaList.length,
            ),
          ),

          // SliverToBoxAdapter(
          //   child: Visibility(
          //     visible: settings.cartList.isNotEmpty,
          //     child: Padding(
          //       padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
          //       child: SizedBox(
          //         height: 56,
          //         child: TextField(
          //           controller: textEditingController,
          //           decoration: InputDecoration(
          //             border: OutlineInputBorder(
          //               borderSide: const BorderSide(color: Color(0xFFB29696)),
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             fillColor: Theme
          //                 .of(context)
          //                 .brightness == Brightness.dark ? null : Colors.white,
          //             isDense: true,
          //             labelText: AppLocalizations.of(context).translate("press_for_notes"),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(settings),
    );
  }

  Widget _buildBottomNavigationBar(MySettings settings) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 8),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: settings.cartList.isEmpty ? null : () {
                    // sendOrder(settings);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SendOrdPage()));
                  },
                  child: Text(AppLocalizations.of(context).translate("gl_send"), style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void deleteCart(MySettings settings, CartModel cartList, int index) {
    //textEditingController.text = "";
    settings.cartList.removeAt(index);
    settings.saveAndNotify();
    widget.refreshCart(settings);
  }

  void deleteVitrinaList(MySettings settings, VitrinaModel vitrinaList, int index) {
    //textEditingController.text = "";
    settings.vitrinaList.removeAt(index);
    settings.saveAndNotify();
    widget.refreshCart(settings);
}


  void showSuccessInfo(MySettings settings) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("sent_ord"))));
  }

}



