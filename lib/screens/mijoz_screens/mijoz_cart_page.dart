
import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/vitrina.dart';
import 'package:flutter_djolis/screens/home/send_ord_page.dart';
import 'package:flutter_djolis/screens/mijoz_screens/mijoz_send_ord_page.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';
import '../../models/dic_prod.dart';
import '../common/photo.dart';
import 'dubai_mijoz_send_ord_page.dart';
import 'mijoz_detail_page.dart';

class MijozCartPage extends StatefulWidget {
  final Function refreshCart;
  const MijozCartPage(this.refreshCart, {super.key});

  @override
  State<MijozCartPage> createState() => _MijozCartPageState();
}

class _MijozCartPageState extends State<MijozCartPage> {
  List<DicProd> filteredProds = DataService.prods.where((prod) => prod.hasVitrina == 1 || prod.prevOstVitrina != 0 || prod.ostVitrina != 0 || prod.savdoVitrina != 0).toList();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [

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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 130,
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
                        child: Slidable(
                          endActionPane: ActionPane(
                            extentRatio: 0.20,
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                backgroundColor: Colors.red,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                icon: Icons.delete_outline,
                                onPressed: (BuildContext context1) async {
                                  Future.delayed(const Duration(milliseconds: 200), () async {
                                    deleteCart(settings, settings.cartList[index], index);
                                  });
                                },
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                Future.delayed(const Duration(milliseconds: 300));
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPage(
                                      settings.cartList[index].prod!,
                                      false,
                                    ),
                                  ),
                                );
                                widget.refreshCart(settings);
                              },
                              child: Padding(
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
                                              url: settings.cartList[index].prod!.picUrl,
                                              title: settings.cartList[index].prod!.name,
                                            ),
                                          ),
                                        );
                                      },
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
                                            imageUrl: settings.cartList[index].prod!.picUrl,
                                            fit: BoxFit.contain,
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
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Product Name
                                          Text(
                                            settings.cartList[index].prod!.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Order details
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.shopping_cart_outlined,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          "${AppLocalizations.of(context).translate("order")}: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                        Text(
                                                          settings.cartList[index].qty.toInt().toString(),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${AppLocalizations.of(context).translate("price")}: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                        Text(
                                                          Utils.myNumFormat0(settings.cartList[index].price),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color.fromRGBO(120, 46, 76, 1),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Total with cashback
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [
                                                          Color.fromRGBO(120, 46, 76, 1),
                                                          Color.fromRGBO(140, 56, 90, 1),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color.fromRGBO(120, 46, 76, 0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      Utils.myNumFormat0(settings.cartList[index].summ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
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
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: settings.cartList.length,
            ),
          ),
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
          height: 70,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${AppLocalizations.of(context).translate("gl_summa_ord")}  ${Utils.myNumFormat0(settings.itogSumm)}", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: settings.cartList.isEmpty ? null : () async {
                    if(DataService.debt.toDouble() > DataService.creditLimit.toDouble()){
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.warning,
                        animType: AnimType.rightSlide,
                        desc: "${AppLocalizations.of(context).translate("cannot_send_ord")}\n\n${AppLocalizations.of(context).translate("cosmetolog_phone")}:${settings.clientPhone}",
                        descTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        btnOkOnPress: () {},
                      ).show();
                      return;
                    }
                    if(settings.serverUrl.contains("http://212.109.199.213:3143")){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MijozSendOrdPage()));
                    }else{
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DubaiMijozSendOrdPage()));
                    }
                        },
                  child: Text(AppLocalizations.of(context).translate("gl_send"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
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


  void showSuccessInfo(MySettings settings) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("sent_ord"))));
  }




}