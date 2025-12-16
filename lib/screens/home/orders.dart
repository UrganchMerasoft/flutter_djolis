import 'dart:convert';
import 'dart:io';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/core/mysettings.dart';
import 'package:flutter_djolis/services/utils.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _first = true;
  bool _isLoading = false;
  int currentValue = 1;
  List<dynamic> orders = [];
  List<dynamic> ordList = [];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context, listen: false);
    if (_first) {
      _first = false;
      getOrders(settings);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/back_wallpaper.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate("profile_open_orders"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedToggleSwitch.size(
                    current: currentValue,
                    values: const [1, 2],
                    iconOpacity: 1,
                    height: 60,
                    indicatorSize: const Size.fromWidth(130),
                    borderWidth: 0,
                    customIconBuilder: (context, local, global) {
                      switch (local.value) {
                        case 1:
                          return Text(
                            AppLocalizations.of(context).translate("active_order"),
                            style: TextStyle(
                              color: Color.lerp(Colors.white, Colors.white, local.animationValue),
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          );
                        case 2:
                          return Text(
                            AppLocalizations.of(context).translate("archive_order"),
                            style: TextStyle(
                              color: Color.lerp(Colors.white, Colors.white, local.animationValue),
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          );
                        default:
                          return const Text("");
                      }
                    },
                    style: ToggleStyle(
                      indicatorColor: Theme.of(context).primaryColor,
                      borderColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      backgroundColor: Colors.transparent,
                    ),
                    selectedIconScale: 1,
                    onChanged: (value) {
                      currentValue = value;
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: orders.where((v) {
                  if (currentValue == 1) {
                    return v["status_id"] == 0;
                  }
                  return v["status_id"] != 0;
                }).isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).translate("gl_no_data"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          itemCount: orders.length > 2 && currentValue == 2 ? 2 : orders.length,
                          itemBuilder: (context, index) {
                            return Visibility(
                              visible: currentValue == 1
                                  ? (Utils.checkDouble(orders[index]["status_id"]).toInt() == 0)
                                  : (Utils.checkDouble(orders[index]["status_id"]).toInt() != 0),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Slidable(
                                  enabled: settings.clientPhone.startsWith("+971"),
                                  endActionPane: ActionPane(
                                    extentRatio: 0.3,
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) async {
                                          await _downloadAndShareInvoicePDF(
                                              context,
                                              settings,
                                              Utils.checkDouble(orders[index]["invoice_id"]).toInt(),
                                              Utils.checkDouble(orders[index]["order_id"]).toInt()
                                          );
                                        },
                                        backgroundColor: Colors.blue.withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        icon: Icons.share,
                                        label: AppLocalizations.of(context).translate("gl_share"),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            openOrder(settings, orders[index]);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withOpacity(0.2),
                                                  Colors.white.withOpacity(0.1),
                                                ],
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).primaryColor,
                                                          borderRadius: BorderRadius.circular(20),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "# ${orders[index]["id"]}",
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            shadows: [
                                                              Shadow(
                                                                offset: Offset(0, 1),
                                                                blurRadius: 2,
                                                                color: Colors.black26,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          orders[index]["curdate_str"].toString(),
                                                          textAlign: TextAlign.center,
                                                          style: const TextStyle(
                                                            color: Colors.black54,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.withOpacity(0.6),
                                                          borderRadius: BorderRadius.circular(20),
                                                          border: Border.all(
                                                            color: Colors.green,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          Utils.myNumFormat0(Utils.checkDouble(orders[index]["itog_summ"])),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            shadows: [
                                                              Shadow(
                                                                offset: Offset(0, 1),
                                                                blurRadius: 2,
                                                                color: Colors.black26,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          orders[index]["notes"],
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w400,
                                                            shadows: [
                                                              Shadow(
                                                                offset: Offset(0, 1),
                                                                blurRadius: 2,
                                                                color: Colors.black26,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.7),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            getStatusIcon(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                                            const SizedBox(width: 4),
                                                            getStatusText(settings, Utils.checkDouble(orders[index]["status_id"]).toInt()),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
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
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getOrders(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-orders");
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
      // if (context.mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      // }
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
      setState(() {
        orders = data!["d"]["ords"];
        ordList = data!["d"]["list"];
        _isLoading = false;
      });
    }
  }

  void openOrder(MySettings settings, order) async {
    debugPrint("$ordList");
    List<dynamic> list = ordList.where((v) => v["doc_id"] == order["id"]).toList();
    debugPrint("$list");

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: list.isNotEmpty
                  ? MediaQuery.of(context).size.height * 0.75
                  : 220,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3b82f6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF3b82f6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate("order_details"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1f2937),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  if (list.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["name"].toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.inventory_2_rounded,
                                      label: "${item["qty"]}",
                                      bgColor: const Color(0xFF3b82f6).withOpacity(0.1),
                                      color: const Color(0xFF3b82f6),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      icon: Icons.sell_outlined,
                                      label: Utils.myNumFormat0(Utils.checkDouble(item["price"])),
                                      bgColor: const Color(0xFF10b981).withOpacity(0.1),
                                      color: const Color(0xFF10b981),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFf59e0b),
                                            Color(0xFFf97316),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFf59e0b).withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        Utils.myNumFormat0(Utils.checkDouble(item["summ"])),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inbox_outlined,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).translate("gl_no_data"),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndShareInvoicePDF(BuildContext context, MySettings settings, int invoiceId, int orderId) async {
    // Context ni saqlab qolamiz
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate("wait")))
    );

    try {
      // URL da invoiceId va orderId parametrlarini qo'shamiz
      Uri uri = Uri.parse("http://37.230.115.134/telegram_bot_pdf/esale_dubai_invoice.php?inv_id=$invoiceId&order_id=$orderId");

      // GET so'rov yuboramiz (POST o'rniga)
      Response res = await post(uri);

      if (res.statusCode == 200) {
        // PDF faylni vaqtinchalik saqlash
        final bytes = res.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/invoice_${invoiceId}_$orderId.pdf');
        await file.writeAsBytes(bytes);

        // Context tekshirish va origin hisoblash
        Rect? origin;
        if (context.mounted) {
          final renderBox = context.findRenderObject();
          if (renderBox is RenderBox) {
            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            if (size.width > 0 && size.height > 0) {
              origin = position & size;
            }
          }
        }

        // Agar origin null yoki nol bo'lsa, fallback qiymat berish
        // iOS 26 uchun MAJBURIY!
        origin ??= Rect.fromLTWH(0, 0, 100, 100);

        // PDF faylni share qilish
        final params = ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: origin,
        );

        final result = await SharePlus.instance.share(params);

        // Share natijasini tekshirish
        if (context.mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_shared_successfully"))));
          } else if (result.status == ShareResultStatus.dismissed) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("share_cancelled"))));
          } else {
            // ShareResultStatus.unavailable
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("share_unavailable")), backgroundColor: Colors.orange));
          }
        }
      } else {
        throw Exception('Failed to download PDF: ${res.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_download_error")), backgroundColor: Colors.red));
      }
      debugPrint("PDF download error: $e");
    }
  }

  getStatusText(MySettings settings, int status_id) {
    if (status_id == 1) {
      return Text(AppLocalizations.of(context).translate("accepted"), style: const TextStyle(color: Colors.green, fontSize: 12),);
    }
    if (status_id == 9) {
      return Text(AppLocalizations.of(context).translate("denied"), style: const TextStyle(color: Colors.red, fontSize: 12),);
    }
    return Text(AppLocalizations.of(context).translate("new"), style: const TextStyle(color: Colors.blue, fontSize: 12),);
  }

  getStatusIcon(MySettings settings, int status_id) {
    if (status_id == 1) {
      return const Icon(Icons.check_box, color: Colors.green, size: 16);
    }
    if (status_id == 1) {
      return const Icon(Icons.close, color: Colors.red, size: 16);
    }
    return const Icon(Icons.check, color: Colors.blue, size: 16);
  }
}
