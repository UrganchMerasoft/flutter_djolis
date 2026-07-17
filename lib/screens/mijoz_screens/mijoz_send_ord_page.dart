import 'dart:convert';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/models/payed_order_model.dart';
import 'package:flutter_djolis/screens/mijoz_screens/mijoz_bank_cards_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/bank_cards_model.dart';
import '../../models/new_payme_model.dart';
import '../../services/utils.dart';

class MijozSendOrdPage extends StatefulWidget {
  const MijozSendOrdPage({super.key});

  @override
  State<MijozSendOrdPage> createState() => _MijozSendOrdPageState();
}

class _MijozSendOrdPageState extends State<MijozSendOrdPage> {
  TextEditingController commentController = TextEditingController();

  List<NewPaymeModel> paymeList = [];
  List<PayedOrderModel> payedOrders = [];
  List<BankCardsModel> bankCards = [];
  String? selectedCardPan;
  TextEditingController summController = TextEditingController();
  TextEditingController smsCodeController = TextEditingController();
  bool _isSmsSent = false;
  bool isPaying = false;
  bool paymentConfirmed = false;
  String transferId = "";
  final cardImages = [
    "assets/images/blue_card.png",
    "assets/images/card_backgr.png",
    "assets/images/bank_background.jpg",
    "assets/images/backgroundimage.png",
  ];
  double totalSumm = 0;
  bool isSending = false;
  File? selectedImage1;
  File? selectedImage2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBankCards(Provider.of<MySettings>(context, listen: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context).translate("verify_ord")),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).translate("set_pay_info"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            selectedCardPan = null;
                            _resetPaymentFlow();
                          });
                        },
                        child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              border: selectedCardPan == null ? Border.all(color: Colors.greenAccent, width: 3) : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(settings.clientName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis)),
                                      if (selectedCardPan == null) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(child: Text(settings.payInfo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis)),
                                      IconButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: settings.payInfo));
                                            showSuccessSnackBar(AppLocalizations.of(context).translate("gl_successfully_copied"));
                                          },
                                          icon: const Icon(Icons.copy, color: Colors.white, size: 20))
                                    ],
                                  ),
                                ],
                              ),
                            )),
                      ),
                      ...bankCards.asMap().entries.map((entry) {
                        final card = entry.value;
                        final imagePath = cardImages[entry.key % cardImages.length];
                        final isSelected = selectedCardPan == card.pan;
                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                selectedCardPan = isSelected ? null : card.pan;
                                _resetPaymentFlow();
                                if (selectedCardPan != null) {
                                  summController.text = Utils.numFormat0.format(settings.itogSumm);
                                }
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.55,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: Colors.greenAccent, width: 3) : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis)),
                                        if (isSelected) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(Utils.formatCardNumber(card.pan), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text(card.expiry.length == 4 ? "${card.expiry.substring(0, 2)}/${card.expiry.substring(2)}" : card.expiry, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const MijozBankCardsPage()));
                          if (!mounted) return;
                          getBankCards(Provider.of<MySettings>(context, listen: false));
                        },
                        child: Container(
                          width: 70,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).primaryColor),
                          ),
                          child: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (selectedCardPan != null) ...[
                Text(AppLocalizations.of(context).translate("enter_summ"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: summController,
                  readOnly: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
                  decoration: InputDecoration(
                    isDense: true,
                    fillColor: Colors.grey.shade200,
                    labelText: AppLocalizations.of(context).translate("enter_summ"),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_isSmsSent && !paymentConfirmed) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: smsCodeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      labelText: AppLocalizations.of(context).translate("enter_sms_code"),
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 25),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(AppLocalizations.of(context).translate("enter_6_digit_code"), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (!paymentConfirmed)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(MediaQuery.of(context).size.width, 50),
                      backgroundColor: isPaying ? Colors.grey : Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isPaying ? null : () => payWithCard(settings),
                    child: Text(
                      isPaying
                          ? AppLocalizations.of(context).translate("wait")
                          : _isSmsSent
                              ? AppLocalizations.of(context).translate("gl_confirm")
                              : AppLocalizations.of(context).translate("dash_do_pay"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(child: Text(AppLocalizations.of(context).translate("payment_confirmed"), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500))),
                    ],
                  ),
              ],
              if (selectedCardPan == null) ...[
              Text(AppLocalizations.of(context).translate("pin_cheque"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: selectedImage1 != null ? 0 : 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {

                        pickScreenshot(settings, 1);
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.width * 0.5,
                        width: selectedImage1 != null ? MediaQuery.of(context).size.width * 0.4 : null,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                          image: selectedImage1 != null ? DecorationImage(image: FileImage(selectedImage1!), fit: BoxFit.cover) : null,
                        ),
                        child: selectedImage1 != null
                            ? const SizedBox.shrink()
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined),
                            const SizedBox(height: 5),
                            Text(AppLocalizations.of(context).translate("add_screenshot"), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                            Text("(${AppLocalizations.of(context).translate("required")})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange))
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(visible: selectedImage1 != null, child: const SizedBox(width: 10)),
                  Visibility(
                    visible: selectedImage1 != null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        debugPrint("add screenshot 2");
                        pickScreenshot(settings, 2);
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.width * 0.5,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                          image: selectedImage2 != null ? DecorationImage(image: FileImage(selectedImage2!), fit: BoxFit.cover) : null,
                        ),
                        child: selectedImage2 != null
                            ? const SizedBox.shrink()
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined),
                            const SizedBox(height: 5),
                            Text(AppLocalizations.of(context).translate("add_screenshot"), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                            Text("(${AppLocalizations.of(context).translate("optional")})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextFormField(
                  controller: commentController,
                  decoration: InputDecoration(
                    isDense: true,
                    fillColor: Colors.white,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(14)),
                    labelText: AppLocalizations.of(context).translate("akt_sverka_notes"),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue), borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade500),
                  const SizedBox(width: 5),
                  Expanded(child: Text(AppLocalizations.of(context).translate("notes_warning"), style: TextStyle(color: Colors.orange.shade500, fontSize: 12))),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(20)),
            height: 140,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(AppLocalizations.of(context).translate("gl_summa_ord"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                      Text(Utils.numFormat0.format(settings.itogSumm), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                fixedSize: Size(MediaQuery.of(context).size.width, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context).translate("gl_back"), style: TextStyle(color: Theme.of(context).primaryColor))),
                        ),
                        if (selectedCardPan == null || paymentConfirmed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                fixedSize: Size(MediaQuery.of(context).size.width, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),

                              onPressed: isSending ? null : () {
                                if (selectedCardPan == null && selectedImage1 == null) {
                                  showRedSnackBar(AppLocalizations.of(context).translate("please_pin_screenshot"));
                                } else {
                                  sendOrder(settings);
                                }
                              },
                              child: isSending
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : Text(AppLocalizations.of(context).translate("gl_send"), style: TextStyle(color: Theme.of(context).primaryColor))),
                        ),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getBankCards(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName()) ?? "";

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-cards-get");
    try {
      final res = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": deviceName,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "mijoz_id": settings.mijozId,
          "clientId": settings.clientId,
        }),
      );

      final data = jsonDecode(res.body);
      if (data == null || data["ok"] != 1) return;

      final List<dynamic> cardsData = data['d'] ?? [];
      if (!mounted) return;
      setState(() {
        bankCards = cardsData.map((item) => BankCardsModel.fromMapObject(item)).toList();
        if (selectedCardPan != null && !bankCards.any((c) => c.pan == selectedCardPan)) {
          selectedCardPan = null;
        }
      });
    } catch (e) {
      debugPrint("getBankCards error: $e");
    }
  }

  void _resetPaymentFlow() {
    _isSmsSent = false;
    paymentConfirmed = false;
    transferId = "";
    smsCodeController.clear();
  }

  String convertExpiryToYYMM(String mmYy) {
    if (mmYy.length != 4) return mmYy;

    String mm = mmYy.substring(0, 2);
    String yy = mmYy.substring(2, 4);
    return '$yy$mm';
  }

  Future<void> payWithCard(MySettings settings) async {
    if (!_isSmsSent) {
      setState(() => isPaying = true);
      final ok = await checkCardAndRequestCode(settings);
      if (!mounted) return;
      setState(() {
        isPaying = false;
        _isSmsSent = ok;
      });
    } else {
      if (smsCodeController.text.trim().length != 6) {
        showRedSnackBar(AppLocalizations.of(context).translate("enter_6_digit_code"));
        return;
      }
      await verifySmsCodeAndPay(settings);
      // To'lov tasdiqlangach buyurtma avtomatik yuboriladi.
      if (mounted && paymentConfirmed) {
        sendOrder(settings);
      }
    }
  }

  Future<bool> checkCardAndRequestCode(MySettings settings) async {
    final card = bankCards.firstWhere((c) => c.pan == selectedCardPan);
    String fcmToken = await Utils.getToken();
    String deviceName = (await Utils.getDeviceName()) ?? "";

    const String url = "http://176.96.241.199:3199/api-djolis-mijoz/new-ipak";

    final Map<String, dynamic> body = {
      "client_id": settings.clientId,
      "mijoz_id": settings.mijozId,
      "pan": card.pan,
      "expiry": convertExpiryToYYMM(card.expiry),
      "summ": settings.itogSumm.round(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": deviceName,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == 1 && data['d']['success'] == 1) {
          transferId = data['d']['transfer_id'];
          showSuccessSnackBar(AppLocalizations.of(context).translate("sms_code_request"));
          return true;
        } else {
          if (kDebugMode) debugPrint("new-ipak rad etdi: ${response.body}");
          showRedSnackBar(AppLocalizations.of(context).translate("unknown_error"));
        }
      } else {
        if (kDebugMode) debugPrint("new-ipak server xatosi ${response.statusCode}: ${response.body}");
        showRedSnackBar(AppLocalizations.of(context).translate("send_sms_failed"));
      }
    } catch (e) {
      debugPrint("Ulanishda xatolik: $e");
      if (mounted) {
        showRedSnackBar(AppLocalizations.of(context).translate("connection_error"));
      }
    }
    return false;
  }

  Future<void> verifySmsCodeAndPay(MySettings settings) async {
    setState(() => isPaying = true);

    try {
      final card = bankCards.firstWhere((c) => c.pan == selectedCardPan);
      String fcmToken = await Utils.getToken();
      String deviceName = (await Utils.getDeviceName()) ?? "";

      const String url = "http://176.96.241.199:3199/api-djolis-mijoz/new-ipak-sms";

      final Map<String, dynamic> body = {
        "transfer_id": transferId,
        "code": smsCodeController.text,
        "client_id": settings.clientId,
        "mijoz_id": settings.mijozId,
        "pan": card.pan,
        "expiry": convertExpiryToYYMM(card.expiry),
        // new-ipak dagi summ bilan bir xil bo'lishi shart, aks holda gateway rad etadi.
        "summ": settings.itogSumm.round(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'lang': settings.locale.languageCode,
          'fcm_token': fcmToken,
          'phone': settings.clientPhone,
          'device_name': deviceName,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == 1 && data['d']['success'] == 1) {
          setState(() {
            paymentConfirmed = true;
          });
          showSuccessSnackBar(AppLocalizations.of(context).translate("payment_confirmed"));
        } else {
          if (kDebugMode) debugPrint("new-ipak-sms rad etdi: ${response.body}");
          showRedSnackBar(AppLocalizations.of(context).translate("payment_failed"));
        }
      } else {
        if (kDebugMode) debugPrint("new-ipak-sms server xatosi ${response.statusCode}: ${response.body}");
        showRedSnackBar("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Ulanishda xatolik: $e");
      if (mounted) {
        showRedSnackBar(AppLocalizations.of(context).translate("connection_error"));
      }
    } finally {
      if (mounted) {
        setState(() => isPaying = false);
      }
    }
  }

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  void showOrderSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      title: AppLocalizations.of(context).translate("order_accepted"),
      desc: AppLocalizations.of(context).translate(paymentConfirmed ? "payment_and_order_success" : "sent_ord"),
      descTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      btnOkText: AppLocalizations.of(context).translate("got_it"),
      btnOkOnPress: () {
        if (mounted) Navigator.pop(context);
      },
    ).show();
  }

  /// Buyurtma yuborilmadi. To'lov o'tgan bo'lsa, mijoz pulini yo'qotmasligi uchun
  /// bu holatni alohida ko'rsatamiz va qayta to'lamasdan qayta yuborishni taklif qilamiz.
  void onOrderSendFailed(MySettings settings, String fallbackMsg) {
    if (!mounted) return;
    if (paymentConfirmed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        title: AppLocalizations.of(context).translate("order_not_sent"),
        desc: AppLocalizations.of(context).translate("payment_ok_order_failed"),
        descTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        btnOkText: AppLocalizations.of(context).translate("try_again"),
        btnOkOnPress: () => sendOrder(settings),
      ).show();
    } else {
      showRedSnackBar(fallbackMsg);
    }
  }


  void sendOrder(MySettings settings) async {

    setState(() => isSending = true);

    try {
      final uploadTasks = <Future<String?>>[
        if (selectedImage1 != null) sendToTelegramAndGetFileId(settings, selectedImage1!),
        if (selectedImage2 != null) sendToTelegramAndGetFileId(settings, selectedImage2!),
      ];

      final results = await Future.wait(uploadTasks);

      if (selectedImage1 != null && results[0] == null) {
        onOrderSendFailed(settings, "Rasmni yuborishda xatolik. Qayta urinib ko'ring.");
        return;
      }

      final successfulFileIds = results.whereType<String>().toList();

      final uri = Uri.parse("${settings.serverUrl}/api-djolis/send-mijoz-order");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "phone": settings.clientPhone,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode({
          "notes": commentController.text,
          "clientId": settings.clientId,
          "mijozId": settings.mijozId,
          "itogSumm": settings.itogSumm,
          "myUuid": "",
          "list": settings.cartList,
          "file_ids": successfulFileIds,
        }),
      ).timeout(const Duration(seconds: 5));

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == 1) {
          settings.cartList.clear();
          settings.vitrinaList.clear();
          settings.saveAndNotify();
          showOrderSuccessDialog();
        } else {
          if (kDebugMode) debugPrint("send-mijoz-order rad etdi: ${response.body}");
          onOrderSendFailed(settings, AppLocalizations.of(context).translate("error"));
        }
      } else {
        if (kDebugMode) debugPrint("send-mijoz-order server xatosi ${response.statusCode}: ${response.body}");
        onOrderSendFailed(settings, "Server xatoligi: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("send-mijoz-order ulanish xatosi: $e");
      if (context.mounted) {
        onOrderSendFailed(settings, "Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  void pickScreenshot(MySettings settings, int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (index == 1) {
          selectedImage1 = File(image.path);
        } else {
          selectedImage2 = File(image.path);
        }
      });
      debugPrint("Rasm tanlandi: ${image.path}");
    } else {
      debugPrint("Rasm tanlanmadi.");
    }
  }

  Future<String?> sendToTelegramAndGetFileId(MySettings settings, File imageFile) async {
    // print("BOT: ${settings.botToken} ChatID: ${settings.botChatId}");
    String botToken = settings.botToken;
    String chatId = settings.botChatId.toString();

    String productNames = settings.cartList.asMap().entries.map((entry) {
      int index = entry.key + 1;
      String name = entry.value.prod?.name ?? "Noma'lum mahsulot";
      return "$index. $name";
    }).join("\n");

    if (productNames.isEmpty) {
      productNames = "Mahsulotlar yo'q";
    }

    final uri = Uri.parse('https://api.telegram.org/bot$botToken/sendPhoto');
    var request = http.MultipartRequest('POST', uri)
      ..fields['chat_id'] = chatId
      ..fields['caption'] = "${AppLocalizations.of(context).translate("mijoz_id")}: ${settings.mijozId}\n${AppLocalizations.of(context).translate("mijoz_name")}: ${settings.mijozName}\n📞 ${settings.mijozPhone}\n\n$productNames\n\n${AppLocalizations.of(context).translate("gl_summa")}: ${Utils.myNumFormat(Utils.numFormat0, settings.itogSumm)}"
      ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final fileId = data['result']['photo'].last['file_id'];
          debugPrint("Rasm Telegramga yuborildi. file_id: $fileId");
          return fileId;
        } else {
          debugPrint("Telegram API xatoligi: ${data['description']}");
          return null;
        }
      } else {
        debugPrint("Telegramga yuborishda xatolik: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Telegramga yuborishda istisno: $e");
      return null;
    }
  }
}