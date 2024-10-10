import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:provider/provider.dart';

class DetailPage extends StatefulWidget {
  final DicProd prod;
  const DetailPage(this.prod, {super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin{

  TextEditingController amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _controller ;
  late Animation _animation;
  bool _first = true;
  late CartModel cart;
  double qty = 0;
  double price = 0;
  double summ = 0;


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween(begin: 300.0, end: 50.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    amountController.text = 0.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    if (_first) {
      print("${settings.serverUrl}/pics/${widget.prod.id}.jpg");
      _first = false;
      getFirtData(settings);
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(AppLocalizations.of(context).translate("prod_info")),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 70,
                            color: Theme.of(context).primaryColor,
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: CachedNetworkImage(
                                imageUrl: "${settings.serverUrl}/pics/${widget.prod.id}.jpg",
                                errorWidget: (context, v, d) {
                                  return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: const DecorationImage(image: AssetImage("assets/images/no_image_available.png"),fit: BoxFit.cover),
                                      ));
                                },
                                height: 310,
                                width: 350,
                                fit: BoxFit.contain,
                              )
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 18, right: 18, top: 8),
                        child: Text(widget.prod.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${AppLocalizations.of(context).translate("prod_price_kg")}:", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
                                Text(AppLocalizations.of(context).translate("exist_in_wh"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(Utils.myNumFormat0(price), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                                widget.prod.ostQty == 0 ?
                                      Text(AppLocalizations.of(context).translate("not_exist"), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.w500))
                                    : Text(AppLocalizations.of(context).translate("exist"), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocalizations.of(context).translate("amount"), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),),
                               Row(
                                 children: [
                                   Container(
                                     decoration: BoxDecoration(
                                       color: const Color(0x90F4F4F4),
                                       borderRadius: BorderRadius.circular(10),
                                     ),
                                       height: 35,
                                       width: 80,
                                       child: TextField(
                                         focusNode: _focusNode,
                                         controller: amountController,
                                         onChanged: (v) {
                                           qty = Utils.checkDouble(amountController.text.trim());
                                           summ = qty * price;
                                         },
                                         keyboardType: TextInputType.number,
                                         maxLines: 1,
                                         autocorrect: false,
                                         textInputAction: TextInputAction.done,
                                         decoration: InputDecoration(
                                           contentPadding: const EdgeInsets.only(bottom: 4, left: 8),
                                             enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey,), borderRadius: BorderRadius.circular(10)),
                                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.grey)),
                                           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.grey))
                                         ),
          
                                       ),
                                   ),
                                   IconButton(onPressed: (){
                                     setState(() {
                                       qty--;
                                       if (qty < 0) qty = 0;
                                       summ = qty * price;
                                     });
                                     amountController.text = Utils.myNumFormat0(qty);
                                   }, icon: const Icon(Icons.remove), color: Colors.black,),
                                   const Text("|", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),),
                                   IconButton(onPressed: (){
                                     setState(() {
                                       qty++;
                                       summ = qty * price;
                                     });
                                     amountController.text = Utils.myNumFormat0(qty);
                                   }, icon: const Icon(Icons.add), color: Colors.black),
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
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${AppLocalizations.of(context).translate("gl_summa")}: ${Utils.myNumFormat0(summ)}", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: (){
                          saveToCart(settings);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                          child: Row(
                            children: [
                              Text(AppLocalizations.of(context).translate("gl_add"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.white)),
                              const SizedBox(width: 8),
                              const Icon(Icons.shopping_cart_outlined)
                            ],
                          ),
                        )),
                  ],
                ),
              )
            ],
          ),
        ),
      // bottomNavigationBar: ,
    );
  }

  void getFirtData(MySettings settings) {
    bool found = false;
    for (var c in settings.cartList) {
      print(c.prod?.name);
      if (c.prodId == widget.prod.id) {
        cart = c;
        qty = c.qty;
        price = c.price;
        summ = c.summ;
        found = true;
      }
    }
    //print(cart);

    if (found == false) {
      price = widget.prod.price;
      cart = CartModel(prodId: widget.prod.id, qty: 0, price: widget.prod.price, summ: 0);
      cart.prod = widget.prod;
    }
    amountController.text = Utils.myNumFormat0(qty);
  }

  void saveToCart(MySettings settings) {
    if (qty > widget.prod.ostQty / (widget.prod.coeff == 1000 ? 1000 : 1)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Остаток не хватает"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ));
      if (widget.prod.coeff == 1000) {
        qty = widget.prod.ostQty / 1000;
        summ = qty * price;
      } else {
        qty = widget.prod.ostQty;
        summ = qty * price;
      }
      amountController.text = Utils.myNumFormat0(qty);
      return;
    }

    cart.prod = widget.prod;
    cart.qty = qty;
    cart.price = price;
    cart.summ = summ;
    bool added = false;
    for (int i = 0; i < settings.cartList.length; i++) {
      if (settings.cartList[i].prodId == cart.prodId) {
        settings.cartList[i] = cart;
        added = true;
      }
    }
    if (!added) {
      settings.cartList.add(cart);
    }
    settings.saveAndNotify();
    Navigator.pop(context);
  }
}
