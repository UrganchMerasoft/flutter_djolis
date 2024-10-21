import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/screens/home/detail_page.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../core/mysettings.dart';
import '../common/photo.dart';

class CartPage extends StatefulWidget {
  final Function refreshCart;
  const CartPage(this.refreshCart, {super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      body: Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.all(8.0),
        child: Column(
        children: [
          Expanded(
            child: settings.cartList.isEmpty ? Center(child: Text(AppLocalizations.of(context).translate("list_empty")),) : ListView.builder(
              itemCount: settings.cartList.length,
              itemBuilder: (context, index) {
                return settings.cartList[index].prod == null ? const Text("") : Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.white
                      // color: index % 2 == 0 ? (const Color(0xFFFFE9E8)) : null,
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
                                  //onRefresh();
                                });
                              },
                            ),
                          ]
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(settings.cartList[index].prod!)));
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
                                            image: const DecorationImage(image: AssetImage("assets/images/no_image_available.png"),fit: BoxFit.cover),
                                          ));
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
                                          settings.cartList[index].prod!.name, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16)),
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
                                // Row(
                                //   children: [
                                //     Expanded(child: Text("", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500))),
                                //   ],
                                // ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text("${AppLocalizations.of(context).translate("order")}: ${Utils.myNumFormat0(settings.cartList[index].qty)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    Expanded(child: Text("  x  ${Utils.myNumFormat0(settings.cartList[index].price)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085), fontWeight: FontWeight.w500))),
                                    Row(
                                      children: [
                                        const Icon(CupertinoIcons.tags,size: 15,),
                                        const SizedBox(width: 5),
                                        Text(Utils.myNumFormat0(settings.cartList[index].summ), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                );
              },
            ),
          ),
          Visibility(
            visible: settings.cartList.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: SizedBox(height: 56, child: TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFB29696)), borderRadius: BorderRadius.circular(10)),
                  fillColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white,
                  isDense: true,
                  labelText: AppLocalizations.of(context).translate("press_for_notes"),
                ),), ),
            ),
          ),
        ],)
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 2, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${AppLocalizations.of(context).translate("gl_summa")}: ${Utils.myNumFormat0(settings.itogSumm)}", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: settings.cartList.isEmpty ? null : () {
                sendOrder(settings);
              },
              child: Text(AppLocalizations.of(context).translate("gl_send"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void deleteCart(MySettings settings, CartModel cartList, int index) {
    textEditingController.text = "";
    settings.cartList.removeAt(index);
    settings.saveAndNotify();
    widget.refreshCart(settings);

    //Dialog шартмас
    // final action = CupertinoActionSheet(
    //   message:  Text("${AppLocalizations.of(context).translate("gl_delete")}?", style: const TextStyle(fontSize: 15.0)),
    //   actions: <Widget>[
    //     CupertinoActionSheetAction(
    //       isDefaultAction: true,
    //       isDestructiveAction: true,
    //       onPressed: () async {
    //         textEditingController.text = "";
    //         Navigator.pop(context);
    //         settings.cartList.removeAt(index);
    //         settings.saveAndNotify();
    //         widget.refreshCart(settings);
    //       },
    //       child: Text(AppLocalizations.of(context).translate("gl_delete")),
    //     ),
    //   ],
    //   cancelButton: CupertinoActionSheetAction(
    //     child: Text(AppLocalizations.of(context).translate("gl_cancel")),
    //     onPressed: () {
    //       Navigator.pop(context);
    //     },
    //   ),
    // );
    // showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  void sendOrder(MySettings settings) {
    final action = CupertinoActionSheet(
      message: Text("${AppLocalizations.of(context).translate("sent_order")}?\n${AppLocalizations.of(context).translate("summ_for_payment")} " + Utils.myNumFormat0(settings.itogSumm), style: TextStyle(fontSize: 15.0)),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: true,
          isDestructiveAction: true,
          onPressed: () async {
            try {
              Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/send-order");
              Response res = await post(
                  uri,
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    "lang": settings.locale.languageCode,
                    "phone": settings.clientPhone,
                    "Authorization": "Bearer ${settings.token}",
                  },
                  body: jsonEncode({
                    "notes": textEditingController.text,
                    "clientId": settings.clientId,
                    "itogSumm": settings.itogSumm,
                    "list": settings.cartList})
              );

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
                return;
              }

              if (data["ok"] == 1) {
                textEditingController.text = "";
                settings.cartList.clear();
                settings.saveAndNotify();
                showSuccessInfo(settings);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("error"))));
                }
              }
            } catch(e) {
            } finally {
              Navigator.pop(context);
            }

          },
          child:  Text(AppLocalizations.of(context).translate("gl_send")),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(AppLocalizations.of(context).translate("gl_cancel")),
        onPressed: () async {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  void showSuccessInfo(MySettings settings) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("sent_ord"))));
  }
}
