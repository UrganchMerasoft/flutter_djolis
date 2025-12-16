import 'dart:convert';
import 'dart:ui';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  TextEditingController networkController = TextEditingController();
  String networkUrl = "";
  bool isSending = false;
  List<DicProd> filteredProds = DataService.prods.where((prod) => prod.hasVitrina == 1 || prod.prevOstVitrina != 0 || prod.ostVitrina != 0 || prod.savdoVitrina != 0).toList();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Empty state
          settings.cartList.isEmpty
              ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 150,
                        width: double.infinity,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).translate("list_empty"),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Visibility(
                    visible: settings.clientPhone != "+998977406675" && settings.clientPhone.startsWith("+971"),
                    child: InkWell(
                      onTap: (){
                        networkPayDialog(context, settings);
                      },
                      child: Container(
                        height: 100,
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
                        child: Row(
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
                                  isSending ? Text(AppLocalizations.of(context).translate("wait")): Text(AppLocalizations.of(context).translate("card_payment"),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  isSending ? Text(""): Text("network, Visa, Mastercard",
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
                              child: isSending ? CircularProgressIndicator(): Icon(
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
                ],
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
                                                        Icon(
                                                          Icons.attach_money,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
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
                                                  if (settings.cartList[index].cashbackSumm > 0) ...[
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: Colors.green.withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.card_giftcard,
                                                            size: 10,
                                                            color: Colors.green.shade700,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            Utils.myNumFormat0(settings.cartList[index].cashbackSumm),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.green.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
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
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Order
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${AppLocalizations.of(context).translate("gl_summa_ord")} ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                "${Utils.myNumFormat0(settings.itogSumm)} ${settings.clientPhone.startsWith("+998") ? "у.е" : "AED"}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Cashback
                          Row(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${AppLocalizations.of(context).translate("cashback")} ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                "${Utils.myNumFormat0(settings.itogCashbackSumm)} ${settings.clientPhone.startsWith("+998") ? "у.е" : "AED"}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),

                          // Juma Cashback (if applicable)
                          if (DataService.jumaName.isNotEmpty || DataService.jumaSavdoSumm != 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${AppLocalizations.of(context).translate("cashback")} (${DataService.jumaName}) ${Utils.myNumFormat0(DataService.getJuma(settings.itogSumm, DataService.jumaSavdoSumm, DataService.jumaSumm).toDouble())} ${settings.clientPhone.startsWith("+998") ? "у.е" : "AED"}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Send Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: settings.cartList.isEmpty
                              ? [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ]
                              : [
                            const Color.fromRGBO(120, 46, 76, 1),
                            const Color.fromRGBO(140, 56, 90, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: settings.cartList.isEmpty
                            ? []
                            : [
                          BoxShadow(
                            color: const Color.fromRGBO(120, 46, 76, 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: settings.cartList.isEmpty
                              ? null
                              : () async {
                            if (settings.itogSumm + DataService.debt >= DataService.creditLimit) {
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.warning,
                                animType: AnimType.rightSlide,
                                title: AppLocalizations.of(context).translate("limit_warning"),
                                desc: "${AppLocalizations.of(context).translate("credit_limit")}: ${DataService.creditLimit}\n${getDebtText(DataService.debt)}: ${DataService.debt.toDouble().abs()}",
                                descTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                                btnOkOnPress: () {},
                              ).show();
                              return;
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SendOrdPage(
                                    hasPromo: hasPromoProduct(settings.cartList),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context).translate("gl_send"),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),

                              ],
                            ),
                          ),
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
  }

  void deleteCart(MySettings settings, CartModel cartList, int index) {
    settings.cartList.removeAt(index);
    settings.saveAndNotify();
    widget.refreshCart(settings);
  }

  bool hasPromoProduct(List<CartModel> cartList) {
    return cartList.any((element) => element.prod?.hasPromo == 1);
  }

  void showSuccessInfo(MySettings settings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate("sent_ord")),
      ),
    );
  }

  String getDebtText(double checker) {
    if (checker < 0) {
      return AppLocalizations.of(context).translate("pre_paid");
    } else if (checker > 0) {
      return AppLocalizations.of(context).translate("debt");
    } else {
      return AppLocalizations.of(context).translate("balance");
    }
  }

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

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
                    await networkPayment(settings) ;
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
}