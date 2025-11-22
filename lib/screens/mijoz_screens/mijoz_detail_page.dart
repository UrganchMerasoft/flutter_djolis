import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/models/cart.dart';
import 'package:flutter_djolis/models/dic_prod.dart';
import 'package:flutter_djolis/models/vitrina.dart';
import 'package:flutter_djolis/screens/common/photo.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../common/photo_info.dart';
import '../firebase_notifications/video_notifs_page.dart';

class MijozDetailPage extends StatefulWidget {
  final DicProd prod;
  final bool isVitrina;
  const MijozDetailPage(this.prod, this.isVitrina, {super.key});

  @override
  State<MijozDetailPage> createState() => _MijozDetailPageState();
}

class _MijozDetailPageState extends State<MijozDetailPage> with SingleTickerProviderStateMixin{

  TextEditingController amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _controller ;
  late Animation _animation;
  bool _first = true;
  late CartModel cart;
  late VitrinaModel vitrina;
  double prevOst = 0;
  double qty = 0;
  double price = 0;
  double summ = 0;
  
  // Media gallery variables
  PageController _pageController = PageController();
  int _currentMediaIndex = 0;
  List<Widget> _mediaPages = [];
  VideoPlayerController? _videoController;


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
    _initializeMediaPages();
  }
  
  void _initializeMediaPages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _mediaPages = _buildMediaPages();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    if (_first) {
      _first = false;
      getFirstData(settings);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).translate("prod_info"),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Gallery
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Media PageView
                        Container(
                          height: 300,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _mediaPages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentMediaIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: _mediaPages[index],
                              );
                            },
                          ),
                        ),
                        // Media Indicators
                        _buildMediaIndicators(),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Mahsulot ma'lumotlari
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mahsulot nomi
                        Text(widget.prod.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3)),

                        const SizedBox(height: 10),

                        // Narx
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: const EdgeInsets.only(bottom: 0), child: Text("${AppLocalizations.of(context).translate("prod_price_kg")}:", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),),
                            const SizedBox(height: 4),
                            Text(Utils.myNumFormat0(price), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          ],
                        ),

                        const SizedBox(height: 10),

                        const Divider(),
                        const SizedBox(height: 10),
                        // Miqdor
                        Text(AppLocalizations.of(context).translate("amount"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),

                        const SizedBox(height: 5),

                        // Quantity selector
                        Row(
                          children: [
                            // Minus button
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: (){
                                  setState(() {
                                    qty--;
                                    if (qty < 0) qty = 0;
                                    summ = qty * price;
                                  });
                                  amountController.text = Utils.myNumFormat0(qty);
                                },
                                icon: const Icon(Icons.remove),
                                iconSize: 24,
                                color: Colors.black87,
                              ),
                            ),

                            // Input
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    focusNode: _focusNode,
                                    controller: amountController,
                                    onChanged: (v) {
                                      setState(() {
                                        qty = Utils.checkDouble(amountController.text.trim());
                                        summ = qty * price;
                                      });
                                    },
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLines: 1,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Plus button
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: (){
                                  setState(() {
                                    qty++;
                                    summ = qty * price;
                                  });
                                  amountController.text = Utils.myNumFormat0(qty);
                                },
                                icon: const Icon(Icons.add),
                                iconSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Bottom bar
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Jami
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).translate("gl_summa"),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      Utils.myNumFormat0(summ),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Add to Cart button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: (){
                                      if (widget.isVitrina) {
                                        saveToVitrina(settings);
                                        return;
                                      }

                                      if (qty != 0) {
                                        saveToCart(settings);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                AppLocalizations.of(context).translate("add_product")
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.red.shade700,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.shopping_cart_outlined, size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context).translate("gl_add"),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }

  void getFirstData(MySettings settings) {
    bool found = false;
    for (var c in settings.cartList) {
      if (c.prodId == widget.prod.id) {
        cart = c;
        qty = c.qty;
        price = c.price;
        summ = c.summ;
        found = true;
      }
    }

    if (found == false) {
      price = widget.prod.clientPrice;
      cart = CartModel(prodId: widget.prod.id, qty: 0, price: widget.prod.clientPrice, summ: 0, cashbackProcent: widget.prod.cashbackProcent, cashbackSumm: 0);
      cart.prod = widget.prod;
    }
    amountController.text = Utils.myNumFormat0(qty);
  }

  void saveToCart(MySettings settings) {
    if (qty > widget.prod.ostQty / (widget.prod.coeff == 1000 ? 1000 : 1)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).translate("lack_of_prods")),
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
    cart.cashbackSumm = settings.clientPhone.startsWith("+971") ? ((cart.summ * cart.cashbackProcent / 100) * settings.curRate / 1).roundToDouble() * 1 : ((cart.summ * cart.cashbackProcent / 100) * settings.curRate / 500).roundToDouble() * 500;
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

  void getFirstVitrinaData(MySettings settings) {
    bool found = false;
    for (var c in settings.vitrinaList) {
      if (c.prodId == widget.prod.id) {
        vitrina = c;
        qty = c.ost;
        price = c.price;
        summ = c.summ;
        found = true;
      }
    }

    if (found == false) {
      price = widget.prod.clientPrice;
      vitrina = VitrinaModel(prodId: widget.prod.id, prevOst: widget.prod.prevOstVitrina, ost: 0, qty: 0, price: widget.prod.clientPrice, summ: 0);
      vitrina.prod = widget.prod;
    }
    prevOst = widget.prod.prevOstVitrina;
    amountController.text = Utils.myNumFormat0(qty);
  }

  void saveToVitrina(MySettings settings) {
    vitrina.prod = widget.prod;
    vitrina.prevOst = prevOst;
    vitrina.ost = qty;
    vitrina.qty = prevOst - qty;
    vitrina.price = price;
    vitrina.summ = summ;
    bool added = false;
    for (int i = 0; i < settings.vitrinaList.length; i++) {
      if (settings.vitrinaList[i].prodId == vitrina.prodId) {
        settings.vitrinaList[i] = vitrina;
        added = true;
      }
    }
    if (!added) {
      settings.vitrinaList.add(vitrina);
    }
    settings.saveAndNotify();
    Navigator.pop(context);
  }

  void deleteVitrina(MySettings settings) {
    for (int i = 0; i < settings.vitrinaList.length; i++) {
      if (settings.vitrinaList[i].prodId == vitrina.prodId) {
        settings.vitrinaList.removeAt(i);
        settings.saveAndNotify();
        Navigator.pop(context);
        return;
      }
    }
  }
  
  // Media gallery methods
  List<Widget> _buildMediaPages() {
    final settings = Provider.of<MySettings>(context, listen: false);
    List<Widget> pages = [];
    
    // 1. Har doim asoiy mahsulot rasmini qo'shamiz (agar mavjud bo'lsa)
    if (_isValidUrl(widget.prod.picUrl)) {
      pages.add(_buildImagePage(widget.prod.picUrl, isMainImage: true));
    }
    
    // 2. Agar infoPicUrl mavjud va to'g'ri bo'lsa, localizatsiya qilingan rasmni qo'shamiz
    if (_isValidUrl(widget.prod.infoPicUrl)) {
      String localizedImageUrl = _getLocalizedImageUrl(widget.prod.infoPicUrl, settings.locale.languageCode);
      pages.add(_buildImagePage(localizedImageUrl, isMainImage: false));
    }
    
    // 3. Agar videoUrl mavjud va to'g'ri bo'lsa, video player qo'shamiz
    if (_isValidUrl(widget.prod.videoUrl)) {
      pages.add(_buildVideoPage(widget.prod.videoUrl));
    }
    
    // 4. Agar hech qanday media bo'lmasa, default rasm qo'yamiz
    if (pages.isEmpty) {
      pages.add(_buildDefaultImagePage());
    }
    
    return pages;
  }
  
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty || url == "null" || url == "undefined") {
      return false;
    }
    return true;
  }
  
  Widget _buildImagePage(String imageUrl, {required bool isMainImage}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoPage(
              url: imageUrl,
              title: widget.prod.name
            )
          )
        );
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        errorWidget: (context, v, d) {
          // Agar bu asoiy mahsulot rasmi bo'lsa, default image ko'rsatamiz
          if (isMainImage) {
            return _buildDefaultImagePage();
          }
          // Info rasm yoki boshqa rasmlar uchun xatolik matnini ko'rsatamiz
          return Container(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(AppLocalizations.of(context).translate("no_data_found"),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        height: 300,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
  
  Widget _buildDefaultImagePage() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/no_image_red.jpg"),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  
  Widget _buildVideoPage(String videoUrl) {
    return Container(
      height: 300,
      child: FutureBuilder<VideoPlayerController>(
        future: _initializeVideoController(videoUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            final controller = snapshot.data!;
            return Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReelsView(videoUrl)
                        )
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
  
  Future<VideoPlayerController> _initializeVideoController(String videoUrl) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    return controller;
  }
  
  String _getLocalizedImageUrl(String url, String languageCode) {
    const language = ['ru', 'en', 'uz', 'ar'];
    if (language.contains(languageCode)) {
      return url.replaceFirst('/pics/', '/pics/${languageCode}_');
    }
    return url;
  }
  
  Widget _buildMediaIndicators() {
    if (_mediaPages.length <= 1) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_mediaPages.length, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 3),
            width: _currentMediaIndex == index ? 12 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentMediaIndex == index 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}