
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_djolis/screens/home/orders.dart';
import 'package:flutter_djolis/screens/mijoz_screens/mijoz_location_map.dart';
import 'package:flutter_djolis/services/data_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../core/mysettings.dart';
import '../../services/utils.dart';
import 'mijoz_orders.dart';

class MijozProfilePage extends StatefulWidget {
  final MySettings settings;
  const MijozProfilePage({super.key, required this.settings});

  @override
  State<MijozProfilePage> createState() => _MijozProfilePageState();
}

class _MijozProfilePageState extends State<MijozProfilePage> {

  TextEditingController addressController = TextEditingController();
  TextEditingController coordinateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      DataService.getAllSettings(widget.settings);
      addressController.text = settings.mijozAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    DataService.getAllSettings(settings);

    return Scaffold(
      body: Container(
        color: Colors.grey.shade100,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Professional Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Avatar and Name
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Profile Name
                      Text(
                        settings.mijozName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Profile Phone
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              settings.mijozPhone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile Content
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cosmetologist Phone Card
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: AppLocalizations.of(context).translate("cosmetolog_phone"),
                        subtitle: settings.clientPhone,
                        onTap: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: settings.clientPhone,
                          );
                          await launchUrl(launchUri);
                        },
                        actionIcon: Icons.call,
                      ),
                      // const SizedBox(height: 16),
                      // // Client Name Card
                      // _buildInfoCard(
                      //   icon: Icons.person_outline,
                      //   title: AppLocalizations.of(context).translate("mijoz_name"),
                      //   subtitle: settings.mijozName,
                      // ),
                      // const SizedBox(height: 16),
                      // // Client Phone Card
                      // _buildInfoCard(
                      //   icon: Icons.phone_android,
                      //   title: AppLocalizations.of(context).translate("mijoz_phone"),
                      //   subtitle: settings.mijozPhone,
                      // ),
                      const SizedBox(height: 16),
                      // Address Card
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: AppLocalizations.of(context).translate("mijoz_address"),
                        subtitle: settings.mijozAddress.isEmpty ? "Manzil kiritilmagan" : settings.mijozAddress,
                        onTap: () {
                          addressController.text = settings.mijozAddress;
                          showDialog(context: context, builder: (BuildContext context) => setMijozAddress(settings));
                        },
                        actionIcon: Icons.edit,
                      ),
                      const SizedBox(height: 16),
                      // GPS Location Card
                      _buildActionCard(
                        icon: Icons.gps_fixed,
                        title: AppLocalizations.of(context).translate("set_location_with_map"),
                        subtitle: "${settings.mijozGpsLng}, ${settings.mijozGpsLat}",
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
                        },
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // My Orders Button
                            _buildActionCard(
                              icon: Icons.receipt_long,
                              title: AppLocalizations.of(context).translate("profile_open_orders"),
                              subtitle: AppLocalizations.of(context).translate("view_order_history"),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MijozOrdersPage()));
                              },
                            ),
                            const SizedBox(height: 16),
                            // Language Selection Button
                            _buildActionCard(
                              icon: Icons.language,
                              title: AppLocalizations.of(context).translate("language"),
                              subtitle: AppLocalizations.of(context).translate("choose_language"),
                              onTap: () {
                                selectLang(context, settings);
                              },
                            ),
                            const SizedBox(height: 24),
                            // Delete Account Button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                                color: Colors.red.shade50,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    showDeleteAccountInfo(settings);
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade600,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context).translate("delete_account"),
                                          style: TextStyle(
                                            color: Colors.red.shade600,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
  }

  // Helper method for info cards
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    IconData? actionIcon,
    List<Color>? gradient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade50,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.grey.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionIcon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: Icon(
                      actionIcon,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for action cards
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    List<Color>? gradient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void selectLang(BuildContext context, MySettings settings) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final action = CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                settings.language = 0;
                settings.locale = const Locale("uz", "UZ");
                settings.saveAndNotify();
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context).translate("uzbek"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800),
              )),
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 1;
              settings.locale = const Locale("ru", "RU");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("russian"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800)),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 2;
              settings.locale = const Locale("en", "US");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("english"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800)),
          ),

          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              settings.language = 3;
              settings.locale = const Locale("ar", "AR");
              settings.saveAndNotify();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate("arabic"),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.green.shade800)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(AppLocalizations.of(context).translate("gl_cancel"),
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.green.shade800)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      showCupertinoModalPopup(context: context, builder: (context) => action);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
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
                  Text(
                    AppLocalizations.of(context).translate("language"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Language options using the new design
                  _buildLanguageOption(
                    flag: "🇺🇿",
                    title: AppLocalizations.of(context).translate("uzbek"),
                    isSelected: settings.language == 0,
                    onTap: () {
                      settings.language = 0;
                      settings.locale = const Locale("uz", "UZ");
                      settings.saveAndNotify();
                      Navigator.pop(context);
                    },
                  ),
                  _buildLanguageOption(
                    flag: "🇷🇺",
                    title: AppLocalizations.of(context).translate("russian"),
                    isSelected: settings.language == 1,
                    onTap: () {
                      settings.language = 1;
                      settings.locale = const Locale("ru", "RU");
                      settings.saveAndNotify();
                      Navigator.pop(context);
                    },
                  ),
                  _buildLanguageOption(
                    flag: "🇺🇸",
                    title: AppLocalizations.of(context).translate("english"),
                    isSelected: settings.language == 2,
                    onTap: () {
                      settings.language = 2;
                      settings.locale = const Locale("en", "US");
                      settings.saveAndNotify();
                      Navigator.pop(context);
                    },
                  ),
                  _buildLanguageOption(
                    flag: "🇦🇪",
                    title: AppLocalizations.of(context).translate("arabic"),
                    isSelected: settings.language == 3,
                    onTap: () {
                      settings.language = 3;
                      settings.locale = const Locale("ar", "AR");
                      settings.saveAndNotify();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // Helper method for language options
  Widget _buildLanguageOption({
    required String flag,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: 1,
        ),
        color: isSelected ? Colors.blue.shade50 : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue.shade500,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showDeleteAccountInfo(MySettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.red.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                AppLocalizations.of(context).translate("delete_account"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                AppLocalizations.of(context).translate("delete_account_info"),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Contact Info Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "+971 55 262 0505",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "djolis@djolis.com",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // OK Button
              Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog setMijozAddress(MySettings settings) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate("profile_address")),
      actions: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 15, 10),
              child: SizedBox(
                height: 100,
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.top,
                  expands: true,
                  controller: addressController,
                  autofocus: true,
                  minLines: null,
                  maxLines: null,
                  decoration: InputDecoration(
                    isDense: false,
                    fillColor: Colors.grey.shade200,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                    labelText: AppLocalizations.of(context).translate("enter_address"),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),

            Padding(
                padding: const EdgeInsets.all(18),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width, 50),
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (addressController.text == "") {
                        showRedSnackBar(AppLocalizations.of(context).translate("gl_cannot_empty"));
                        return;
                      }
                      await sendMijozAddress(settings);
                      addressController.clear();

                    }, child: Text(AppLocalizations.of(context).translate("profile_save")))
            ),
          ],
        ),
      ],
    );
  }

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }
  void showSuccessSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  Future<void> sendMijozAddress(MySettings settings) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-update");

    Response? res;
    res = await post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "lang": settings.locale.languageCode,
        "fcm_token": fcmToken,
        "phone": settings.clientPhone,
        "Authorization": "Bearer ${settings.token}",
      },
      body: jsonEncode({
        "id": settings.mijozId,
        "address": addressController.text,
        "gps_lat": settings.mijozGpsLat,
        "gps_lng": settings.mijozGpsLng
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      await DataService.getAllSettings(settings);
      settings.mijozAddress = addressController.text;
      settings.saveAndNotify();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

}
