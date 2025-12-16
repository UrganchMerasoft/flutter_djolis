import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class DetailPage extends StatefulWidget {
  final DicProd prod;
  final bool isVitrina;
  const DetailPage(this.prod, this.isVitrina, {super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin {
  TextEditingController amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _controller;
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
      if (widget.isVitrina) {
        getFirstVitrinaData(settings);
      } else {
        getFirstData(settings);
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (widget.isVitrina)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteVitrina(settings),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Media Carousel Section with Hero Animation
                  _buildMediaCarousel(),

                  // Product Info Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.prod.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Price and Stock Section
                        _buildPriceStockSection(context),

                        const SizedBox(height: 24),

                        // Quantity Controller
                        _buildQuantityController(context, settings),

                        const SizedBox(height: 16),

                        // Product Description (if exists)
                        if (widget.prod.info.isNotEmpty)
                          _buildProductInfo(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(context, settings),
        ],
      ),
    );
  }

  Widget _buildMediaCarousel() {
    return Container(
      height: 450,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromRGBO(120, 46, 76, 0.08),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Media PageView
          Expanded(
            child: _mediaPages.isEmpty
                ? _buildDefaultImagePage()
                : PageView.builder(
              controller: _pageController,
              itemCount: _mediaPages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                  child: Hero(
                    tag: 'product_media_${widget.prod.id}_$index',
                    child: _mediaPages[index],
                  ),
                );
              },
            ),
          ),

          // Media Indicators
          _buildMediaIndicators(),

        ],
      ),
    );
  }

  Widget _buildMediaIndicators() {
    if (_mediaPages.length <= 1) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_mediaPages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentMediaIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentMediaIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceStockSection(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              // Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate("prod_price_kg"),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Utils.myNumFormat0(price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color.fromRGBO(120, 46, 76, 1),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isVitrina)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.prod.ostQty > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.prod.ostQty > 0
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            widget.prod.ostQty > 0
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: widget.prod.ostQty > 0
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).translate("exist_in_wh"),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
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
      ),
    );
  }

  Widget _buildQuantityController(BuildContext context, MySettings settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate("amount"),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Minus Button
                  _buildControlButton(
                    icon: Icons.remove,
                    onPressed: () {
                      setState(() {
                        if (widget.prod.coeff == 1000) {
                          if (qty > 0.001) qty -= 0.001;
                        } else {
                          if (qty > 1) qty -= 1;
                        }
                        summ = qty * price;

                        if (widget.isVitrina) summ = (prevOst - qty) * price;

                        if (settings.clientPhone.startsWith("+971")) {
                          widget.prod.cashbackSumm = (summ * widget.prod.cashbackProcent / 100);
                        } else {
                          widget.prod.cashbackSumm = ((summ * widget.prod.cashbackProcent / 100) * settings.curRate / 500).roundToDouble() * 500;
                        }
                      });
                      amountController.text = Utils.myNumFormat0(qty);
                    },
                  ),

                  const SizedBox(width: 12),

                  // Quantity Input
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: amountController,
                          focusNode: _focusNode,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color.fromRGBO(120, 46, 76, 1),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              qty = double.tryParse(value.replaceAll(" ", "").replaceAll(",", "")) ?? 0;
                              summ = qty * price;

                              if (widget.isVitrina) summ = (prevOst - qty) * price;

                              if (settings.clientPhone.startsWith("+971")) {
                                widget.prod.cashbackSumm = (summ * widget.prod.cashbackProcent / 100);
                              } else {
                                widget.prod.cashbackSumm = ((summ * widget.prod.cashbackProcent / 100) * settings.curRate / 500).roundToDouble() * 500;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Plus Button
                  _buildControlButton(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        if (widget.prod.coeff == 1000) {
                          qty += 0.001;
                        } else {
                          qty += 1;
                        }
                        summ = qty * price;

                        if (widget.isVitrina) summ = (prevOst - qty) * price;

                        if (settings.clientPhone.startsWith("+971")) {
                          widget.prod.cashbackSumm = (summ * widget.prod.cashbackProcent / 100);
                        } else {
                          widget.prod.cashbackSumm = ((summ * widget.prod.cashbackProcent / 100) * settings.curRate / 500).roundToDouble() * 500;
                        }
                      });
                      amountController.text = Utils.myNumFormat0(qty);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(120, 46, 76, 1),
            Color.fromRGBO(140, 56, 90, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(120, 46, 76, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.red.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.prod.info,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, MySettings settings) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.95),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cashback Info
                if (!widget.isVitrina && widget.prod.cashbackProcent > 0 && qty != 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${AppLocalizations.of(context).translate("cashback")}: ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          Utils.myNumFormat2(widget.prod.cashbackSumm),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Vitrina Sales Info
                if (widget.isVitrina)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${AppLocalizations.of(context).translate("sales")}: ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          Utils.myNumFormat0(prevOst - qty),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Total and Add Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate("gl_summa"),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Utils.myNumFormat0(summ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color.fromRGBO(120, 46, 76, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromRGBO(120, 46, 76, 1),
                              Color.fromRGBO(140, 56, 90, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
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
                            onTap: () {
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
                                      AppLocalizations.of(context).translate("add_product"),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).translate("gl_add"),
                                  style: const TextStyle(
                                    fontSize: 16,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Media gallery methods
  List<Widget> _buildMediaPages() {
    final settings = Provider.of<MySettings>(context, listen: false);
    List<Widget> pages = [];

    // 1. Main product image
    if (_isValidUrl(widget.prod.picUrl)) {
      pages.add(_buildImagePage(widget.prod.picUrl, isMainImage: true));
    }

    // 2. Info image (localized)
    if (_isValidUrl(widget.prod.infoPicUrl)) {
      String localizedImageUrl = _getLocalizedImageUrl(
        widget.prod.infoPicUrl,
        settings.locale.languageCode,
      );
      pages.add(_buildImagePage(localizedImageUrl, isMainImage: false));
    }

    // 3. Video
    if (_isValidUrl(widget.prod.videoUrl)) {
      pages.add(_buildVideoPage(widget.prod.videoUrl));
    }

    // 4. Default if empty
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
              title: widget.prod.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            errorWidget: (context, v, d) {
              if (isMainImage) {
                return _buildDefaultImagePage();
              }
              return Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).translate("no_data_found"),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImagePage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/no_image_red.jpg"),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPage(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                      color: Colors.black.withOpacity(0.3),
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
                            builder: (context) => ReelsView(videoUrl),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
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
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(120, 46, 76, 1),
                  ),
                ),
              );
            }
          },
        ),
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
      price = widget.prod.price;
      cart = CartModel(
        prodId: widget.prod.id,
        qty: 0,
        price: widget.prod.price,
        summ: 0,
        cashbackProcent: widget.prod.cashbackProcent,
        cashbackSumm: 0,
      );
      cart.prod = widget.prod;
    }
    amountController.text = Utils.myNumFormat0(qty);
  }

  void saveToCart(MySettings settings) {
    if (qty > widget.prod.ostQty / (widget.prod.coeff == 1000 ? 1000 : 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate("lack_of_prods")),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
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
    cart.cashbackSumm = settings.clientPhone.startsWith("+971")
        ? (cart.summ * cart.cashbackProcent / 100)
        : ((cart.summ * cart.cashbackProcent / 100) * settings.curRate / 500).roundToDouble() * 500;

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
      price = widget.prod.price;
      vitrina = VitrinaModel(
        prodId: widget.prod.id,
        prevOst: widget.prod.prevOstVitrina,
        ost: 0,
        qty: 0,
        price: widget.prod.price,
        summ: 0,
      );
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
}