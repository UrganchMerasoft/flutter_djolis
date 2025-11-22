import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/screens/home/profile_page/bank_cards_page.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/bank_cards_model.dart';
import '../../services/utils.dart';

class DubaiUzPayment extends StatefulWidget {
  const DubaiUzPayment({super.key});

  @override
  State<DubaiUzPayment> createState() => _DubaiUzPaymentState();
}

class _DubaiUzPaymentState extends State<DubaiUzPayment> {
  TextEditingController amountController = TextEditingController();

  List<BankCardsModel> bankCards = [];
  String? _selectedPan;
  String? _selectedExpiry;
  int? _selectedCardIndex;
  bool _isLoading = false;
  String networkUrl = "";
  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    getAllBankCards(settings);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate("card_payment")),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: SizedBox(
                  height: 150,
                  child: bankCards.isEmpty
                      ? addCardButton(context)
                      : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bankCards.length + 1,
                      itemBuilder: (context, index) {
                        if (index == bankCards.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                            child: addCardButton(context, isListItem: true),
                          );
                        } else {
                          bool isSelected = _selectedCardIndex == index;
                          final imagePath = images[index % images.length];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                                _selectedPan = bankCards[index].pan;
                                _selectedExpiry = convertExpiryToYYMM(bankCards[index].expiry);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 130,
                                    width: 255,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover, colorFilter: isSelected ? ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken) : null),
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? Border.all(color: Colors.blue, width: 4)
                                          : null,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 5, left: 8),
                                            child: Text(bankCards[index].name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10, left: 8),
                                            child: Text(Utils.formatCardNumber(bankCards[index].pan), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10, left: 8),
                                            child: Text("${bankCards[index].expiry.substring(0, 2)}/${bankCards[index].expiry.substring(2)}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Visibility(visible: isSelected, child: const Icon(Icons.check_circle, size: 70, color: Colors.green)),
                                ],
                              ),
                            ),
                          );
                        }
                      }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 5),
                    Text(AppLocalizations.of(context).translate("select_card_and_enter_amount"), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.orange)),
                  ],
                ),
              ),

               Padding(
                 padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    CurrencyInputFormatter(),
                  ],
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
              const SizedBox(height: 15),
          
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async{}, child: const Text("Pay")),
              const SizedBox(height: 15),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Theme.of(context).primaryColor)),
                  ),
                  onPressed: isSending ? null : () async {
                    print("URL: $networkUrl");
                    print("AMOUNT: ${amountController.text}");
                    if (amountController.text.isEmpty) {
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      return;
                    }
                    setState(() => isSending = true);
                    await networkPayment(settings);
                    if (networkUrl.isNotEmpty) {
                      print("URL: $networkUrl");
                      print("AMOUNT: ${amountController.text}");
                      await launchUrl(
                        Uri.parse(networkUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }

                    if (mounted) {
                      setState(() => isSending = false);
                    }
                  }, child: isSending ? const CircularProgressIndicator() : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/logo-network.png", height: 40),
                    ],
                  )),
              const SizedBox(height: 10),
              ],
          ),
        ),
      ),
    );
  }

  Future<void> getAllBankCards(MySettings settings) async {
    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    _isLoading = true;
    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/cards-get");
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
        debugPrint("getAll Error 1 data null or data['ok] != 1");
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      _isLoading = false;
      if (kDebugMode) {
        debugPrint("getAll 2 Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      final List<dynamic> cardsData = data['d'] ?? [];
      bankCards = cardsData.map((item) => BankCardsModel.fromMapObject(item)).toList();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget addCardButton(BuildContext context, {bool isListItem = false}) {
    Widget buttonContent = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        height: 130,
        width: isListItem ? 130 : MediaQuery.of(context).size.width,
        child: IconButton(
            onPressed: () async{
              bool isOk = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BankCardsPage()));
              if(isOk){
                getAllBankCards(Provider.of<MySettings>(context, listen: false));
              }
            },
            icon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Theme.of(context).primaryColor, size: 50),
                Text(AppLocalizations.of(context).translate("add_card"), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).primaryColor)),
              ],
            )));
    return isListItem ? buttonContent : Center(child: buttonContent);
  }

  final images = [
    "assets/images/blue_card.png",
    "assets/images/card_backgr.png",
    "assets/images/bank_background.jpg",
    "assets/images/backgroundimage.png",
  ];

  String convertExpiryToYYMM(String mmYy) {
    if (mmYy.length != 4) return mmYy;

    String mm = mmYy.substring(0, 2);
    String yy = mmYy.substring(2, 4);
    return '$yy$mm';
  }

  String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate("enter_card_expiry");
    }

    final regex = RegExp(r'^\d{2}/\d{2}$');
    if (!regex.hasMatch(value)) {
      return AppLocalizations.of(context).translate("wrong_formate");
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;

    if (month < 1 || month > 12) {
      return AppLocalizations.of(context).translate("wrong_month");
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return AppLocalizations.of(context).translate("expired_date_card");
    }

    return null;
  }

  Future<void> networkPayment(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/new-ngenius-uz");
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
          "summ": parseAmount(amountController.text),
        }),
      );
      print("RESPONSE: ${res.body}");
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error parsing JSON mijoz_send_ord")));
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
    }
  }

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  double parseAmount(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }


}


class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    final limitedDigits = digitsOnly.length > 16
        ? digitsOnly.substring(0, 16)
        : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      buffer.write(limitedDigits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != limitedDigits.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat numberFormat;

  CurrencyInputFormatter({String locale = 'uz'})
      : numberFormat = NumberFormat.currency(
    locale: locale,
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String value = newValue.text;

    // Faqat raqam va nuqta qoldiramiz
    value = value.replaceAll(RegExp(r'[^\d.]'), '');

    // Ikkita nuqta bo‘lsa, noto‘g‘ri — eski qiymatni qaytaramiz
    if ('.'.allMatches(value).length > 1) {
      return oldValue;
    }

    List<String> parts = value.split('.');

    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Raqamni formatlash (mingliklar bilan)
    String formattedInteger = NumberFormat.decimalPattern().format(int.parse(integerPart.isEmpty ? '0' : integerPart));

    String formatted = decimalPart.isNotEmpty
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}