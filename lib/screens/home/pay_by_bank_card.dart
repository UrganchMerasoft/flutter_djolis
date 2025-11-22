import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/screens/home/profile_page/bank_cards_page.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../models/bank_cards_model.dart';
import '../../services/utils.dart';

class PayByBankCard extends StatefulWidget {
  const PayByBankCard({super.key});

  @override
  State<PayByBankCard> createState() => _PayByBankCardState();
}

class _PayByBankCardState extends State<PayByBankCard> {

  TextEditingController summController = TextEditingController();
  TextEditingController smsCodeController = TextEditingController();

  bool _isLoading = false;
  bool isSending = false;
  bool isCardSelected = false;
  bool _isSmsSent = false;
  List<BankCardsModel> bankCards = [];
  String? _selectedPan;
  String? _selectedExpiry;
  int? _selectedCardIndex;
  String transferId = "";
  bool isLoading = false;


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    getAllBankCards(settings);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate("card_payment")),
        centerTitle: true,
        actions: [
          Visibility(
            visible: bankCards.isEmpty,
            child: IconButton(onPressed: (){
              getAllBankCards(settings);
            }, icon: const Icon(Icons.sync)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 0),
                child: SizedBox(
                    height: 20,
                    child:  Text(AppLocalizations.of(context).translate("choose_bank_card"), textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 17))),
              ),
              SizedBox(
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
                        // This is a bank card item
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
              const SizedBox(height: 10),
              TextFormField(
                onTap: (){
                  if(_selectedCardIndex == null){
                    isCardSelected = false;
                    showRedSnackBar(AppLocalizations.of(context).translate("choose_bank_card"));
                  }else{
                    setState(() {
                      isCardSelected = true;
                    });
                  }
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
                readOnly: !isCardSelected || _isSmsSent,
                controller: summController,
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
              if (_isSmsSent) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: smsCodeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate("enter_sms_code"),
                    isDense: true,
                    fillColor: Colors.grey.shade200,
                    errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                    focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                 Row(
                  children: [
                   const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.orange, size: 25),
                    Flexible(child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 6),
                      child: Text(AppLocalizations.of(context).translate("enter_6_digit_code"), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey),),
                    )),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width, 50),
                    backgroundColor: isSending ? Colors.grey : Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading ? null : () async {
                    if (_selectedCardIndex == null) {
                      showRedSnackBar(AppLocalizations.of(context).translate("choose_bank_card"));
                      return;
                    }
                    if (summController.text.isEmpty) {
                      showRedSnackBar(AppLocalizations.of(context).translate("enter_summ"));
                      return;
                    }
          
                    if (!_isSmsSent) {

                      setState(() {
                        _isSmsSent = true;
                        isCardSelected = false;
                      });

                      await checkCardAndRequestCode(settings);
                    } else {

                      if (smsCodeController.text.isEmpty) {
                        showRedSnackBar(AppLocalizations.of(context).translate("enter_sms_code"));
                        return;
                      }

                      if (smsCodeController.text.trim().length != 6) {
                        showRedSnackBar("SMS kod 6 xonali bo'lishi kerak");
                        return;
                      }
                      await verifySmsCodeAndPay(settings);

                      setState(() {
                        _isSmsSent = false;
                        isCardSelected = true;
                        summController.clear();
                        smsCodeController.clear();
                        _selectedCardIndex = null;
                        _selectedPan = null;
                        _selectedExpiry = null;
                      });
                    }
                  }, child:Text(_isSmsSent ? AppLocalizations.of(context).translate("gl_confirm") : isLoading ? AppLocalizations.of(context).translate("wait") : AppLocalizations.of(context).translate("dash_do_pay")),
              ),
          
            ],
          ),
        ),
      ),
    );
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

  void showRedSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void showSuccessSnackBar(String msg){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  final images = [
    "assets/images/blue_card.png",
    "assets/images/card_backgr.png",
    "assets/images/bank_background.jpg",
    "assets/images/backgroundimage.png",
  ];

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

  String convertExpiryToYYMM(String mmYy) {
    if (mmYy.length != 4) return mmYy;

    String mm = mmYy.substring(0, 2);
    String yy = mmYy.substring(2, 4);
    return '$yy$mm';
  }

  Future<void> checkCardAndRequestCode(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";
    String summ = summController.text.replaceAll(" ", "").replaceAll(" ", "").replaceAll(",", "");

    const String url = "http://176.96.241.199:3199/api-djolis/new-ipak";

    final Map<String, dynamic> body = {
      "client_id": settings.clientId,
      "mijoz_id": settings.mijozId,
      "pan": _selectedPan,
      "expiry": _selectedExpiry,
      "summ": int.parse(summ)
    };

    try {
      final response = await post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "lang": settings.locale.languageCode,
          "fcm_token": fcmToken,
          "phone": settings.clientPhone,
          "device_name": device_name,
          "Authorization": "Bearer ${settings.token}",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == 1 && data['d']['success'] == 1) {
          transferId = data['d']['transfer_id'];
          showSuccessSnackBar(AppLocalizations.of(context).translate("sms_code_request"));
        } else {
          debugPrint("Xatolik: success != 1");
          showRedSnackBar(AppLocalizations.of(context).translate("unknown_error"));
        }
      } else {
        debugPrint("Server xatosi: ${response.statusCode}");
        showRedSnackBar(AppLocalizations.of(context).translate("send_sms_failed"));
      }
    } catch (e) {
      debugPrint("Ulanishda xatolik: $e");
    }
  }

  Future<void> verifySmsCodeAndPay(MySettings settings) async {
    setState(() {
      isLoading = true;
    });

    try {
      String fcmToken = await Utils.getToken();
      String deviceName = await Utils.getDeviceName() ?? "";
      String summ = summController.text.replaceAll(" ", "").replaceAll(" ", "").replaceAll(",", "");

      const String url = "http://176.96.241.199:3199/api-djolis/new-ipak-sms";

      final Map<String, dynamic> body = {
        "transfer_id": transferId,
        "code": smsCodeController.text,
        "client_id": settings.clientId,
        "mijoz_id": settings.mijozId,
        "pan": _selectedPan,
        "expiry": _selectedExpiry,
        "summ": int.parse(summ)
      };

      final response = await post(
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == 1 && data['d']['success'] == 1) {
          String newTransferId = data['d']['transfer_id'];
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: AppLocalizations.of(context).translate("payment_confirmed"),
            descTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            btnOkOnPress: () {},
          ).show();

        } else {
          debugPrint("❌ Xatolik: success != 1");
          _showErrorDialog(AppLocalizations.of(context).translate("payment_failed"));
        }
      } else {
        print(response);
        print(response.body);
        debugPrint("❌ Server xatosii: ${response.statusCode}");
        _showErrorDialog("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Ulanishda xatolik: $e");
      _showErrorDialog(AppLocalizations.of(context).translate("connection_error"));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: AppLocalizations.of(context).translate("unknown_error"),
      desc: message,
      btnOkOnPress: () {},
    ).show();
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

