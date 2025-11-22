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
import 'package:shimmer/shimmer.dart';

class MijozOrdersPage extends StatefulWidget {
  const MijozOrdersPage({super.key});
  @override
  State<MijozOrdersPage> createState() => _MijozOrdersPageState();
}

class _MijozOrdersPageState extends State<MijozOrdersPage> {
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
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).translate("profile_open_orders")),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
          children: [
            // Elegant Toggle Switch
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedToggleSwitch.size(
                current: currentValue,
                values: const [1, 2],
                iconOpacity: 1,
                height: 50,
                indicatorSize: const Size.fromWidth(140),
                borderWidth: 0,
                customIconBuilder: (context, local, global) {
                  switch (local.value) {
                    case 1:
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: Color.lerp(Colors.white, Colors.pink.shade700, local.animationValue),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).translate("active_order"),
                              style: TextStyle(
                                color: Color.lerp(Colors.white, Colors.pink.shade700, local.animationValue),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    case 2:
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: 18,
                              color: Color.lerp(Colors.white, Colors.purple.shade700, local.animationValue),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).translate("archive_order"),
                              style: TextStyle(
                                color: Color.lerp(Colors.white, Colors.purple.shade700, local.animationValue),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    default:
                      return const Text("");
                  }
                },
                style: ToggleStyle(
                  indicatorColor: Colors.white,
                  borderColor: Colors.pink,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: Colors.transparent,
                ),
                selectedIconScale: 1,
                onChanged: (value) {
                  currentValue = value;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : orders.where((v) {
                      if (currentValue == 1) {
                        return v["status_id"] == 0;
                      }
                      return v["status_id"] != 0;
                    }).isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: orders.length > 2 && currentValue == 2 ? 2 : orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final isVisible = currentValue == 1
                                ? (Utils.checkDouble(order["status_id"]).toInt() == 0)
                                : (Utils.checkDouble(order["status_id"]).toInt() != 0);
                                
                            if (!isVisible) return const SizedBox.shrink();
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Slidable(
                                enabled: settings.clientPhone.startsWith("+971"),
                                endActionPane: ActionPane(
                                  extentRatio: 0.25,
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) async {
                                        await _downloadAndShareInvoicePDF(
                                          context,
                                          settings,
                                          Utils.checkDouble(order["invoice_id"]).toInt(),
                                          Utils.checkDouble(order["order_id"]).toInt(),
                                        );
                                      },
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      icon: Icons.share,
                                      label: AppLocalizations.of(context).translate("gl_share"),
                                      borderRadius: BorderRadius.circular(15),
                                      flex: 1,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ],
                                ),
                                child: _buildOrderCard(order, settings),
                              ),
                            );
                          }),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.pink.shade100, Colors.purple.shade100],
              ),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).translate("gl_no_data"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, MySettings settings) {
    final statusId = Utils.checkDouble(order["status_id"]).toInt();
    final isActive = statusId == 0;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            isActive ? Colors.pink.shade50 : Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isActive 
                ? Colors.pink.withValues(alpha: 0.1) 
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openOrder(settings, order),
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
                        gradient: LinearGradient(
                          colors: isActive 
                              ? [Colors.pink.shade300, Colors.purple.shade300]
                              : [Colors.pink.shade300, Colors.purple.shade300],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "#${order["id"]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          getStatusIcon(settings, statusId),
                          const SizedBox(width: 4),
                          getStatusText(settings, statusId),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order["curdate_str"].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (order["notes"] != null && order["notes"].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order["notes"],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (order["notes"] != null && order["notes"].toString().isNotEmpty)
                  const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                    Text(
                      "${AppLocalizations.of(context).translate("total")}: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      Utils.myNumFormat0(Utils.checkDouble(order["itog_summ"])),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
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

  void getOrders(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName())??"";

    setState(() {
      _isLoading = true;
    });
    
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/get-mijoz-own-orders");
    Response? res;
    try {
      res = await post(
        uri,
        body: jsonEncode({
          "mijoz_id": settings.mijozId
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": deviceName,
          "Authorization": "Bearer ${settings.token}",
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (data == null || data["ok"] != 1) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print("Error data null or data['ok] != 1");
      }
      return;
    }
    if (data["ok"] == 1) {
      setState(() {
        orders = data!["d"]["ords"];
        ordList = data["d"]["list"];
        _isLoading = false;
      });
    }
  }

  void openOrder(MySettings settings, order) async {
    debugPrint("$ordList");
    List<dynamic> list = ordList.where((v) => v["doc_id"] == order["id"]).toList();
    debugPrint("$list");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade300, Colors.purple.shade300],
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).translate("order_details"),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (list.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            // gradient: LinearGradient(
                            //   begin: Alignment.topLeft,
                            //   end: Alignment.bottomRight,
                            //   colors: [Colors.white, Colors.pink.shade50],
                            // ),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Header
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Colors.pink.shade300, Colors.purple.shade300],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["name"].toString(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Price Details Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.pink.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context).translate("quantity"),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.blue.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              "${item["qty"]} ${AppLocalizations.of(context).translate("pieces")}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.pink.shade100, Colors.purple.shade100],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context).translate("product_price"),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            Utils.myNumFormat0(Utils.checkDouble(item["price"])),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.pink.shade50, Colors.purple.shade50],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context).translate("total_amount"),
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              Utils.myNumFormat0(Utils.checkDouble(item["summ"])),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple.shade700,
                                              ),
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
                          Icon(
                            Icons.inbox_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).translate("no_data_found"),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadAndShareInvoicePDF(BuildContext context, MySettings settings, int invoiceId, int orderId) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate("wait")))
    );

    try {
      Uri uri = Uri.parse("http://37.230.115.134/telegram_bot_pdf/esale_dubai_invoice.php?inv_id=$invoiceId&order_id=$orderId");

      Response res = await get(uri);

      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/invoice_${invoiceId}_$orderId.pdf');
        await file.writeAsBytes(bytes);

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

        origin ??= const Rect.fromLTWH(0, 0, 100, 100);

        final params = ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: origin,
        );

        final result = await SharePlus.instance.share(params);

        if (context.mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("pdf_shared_successfully"))));
          } else if (result.status == ShareResultStatus.dismissed) {
            ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context).translate("share_cancelled"))));
          } else {
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

  getStatusText(MySettings settings, int statusId) {
    if (statusId == 1) {
      return Text(AppLocalizations.of(context).translate("accepted"), style: const TextStyle(color: Colors.green, fontSize: 12),);
    }
    if (statusId == 9) {
      return Text(AppLocalizations.of(context).translate("denied"), style: const TextStyle(color: Colors.red, fontSize: 12),);
    }
    return Text(AppLocalizations.of(context).translate("new"), style: const TextStyle(color: Colors.blue, fontSize: 12),);
  }

  getStatusIcon(MySettings settings, int statusId) {
    if (statusId == 1) {
      return const Icon(Icons.check_box, color: Colors.green, size: 16);
    }
    if (statusId == 9) {
      return const Icon(Icons.close, color: Colors.red, size: 16);
    }
    return const Icon(Icons.check, color: Colors.blue, size: 16);
  }
}