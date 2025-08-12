import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../core/mysettings.dart';
import '../../../models/bank_cards_model.dart';
import '../../../models/dic_clients.dart';
import '../../../services/utils.dart';

class BankCardsPage extends StatefulWidget {
  const BankCardsPage({super.key});

  @override
  State<BankCardsPage> createState() => _BankCardsPageState();
}

class _BankCardsPageState extends State<BankCardsPage> {
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool _isLoading = false;
  List<DicClients> clients = [];
  List<BankCardsModel> cards = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController expiryController = TextEditingController();
  TextEditingController panController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllCards(settings);
    });
  }


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate("my_bank_cards")),
          centerTitle: true,
          actions:[
            IconButton(onPressed: (){
              showDialog(context: context, builder: (BuildContext context) => addClientDialog(settings, 2, ));
            }, icon: const Icon(Icons.add))
          ]
      ),
      body: cards.isEmpty ? _buildNotFoundWidget(context) : Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final imagePath = images[index % 3];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Slidable(
                      endActionPane: ActionPane(
                        extentRatio: 0.30,
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: Colors.red,
                            icon: Icons.delete,
                            label: AppLocalizations.of(context).translate("gl_delete"),
                            onPressed: (BuildContext context1) async {
                              Future.delayed(const Duration(milliseconds: 200), () async {
                                deleteCard(settings, cards[index].pan);
                              });
                            },
                          ),
                        ],
                      ),
                      child: Container(
                        height: 170,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            image:  DecorationImage(image: AssetImage(imagePath),fit: BoxFit.cover),
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Padding(
                                padding: const EdgeInsets.only(top: 20, left: 12),
                                child: Text(cards[index].name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20, left: 12),
                                child: Text(Utils.formatCardNumber(cards[index].pan), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 20, left: 15),
                                child: Text("${cards[index].expiry.substring(0, 2)}/${cards[index].expiry.substring(2)}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontSize: 18)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: cards.isEmpty,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () {
            showDialog(context: context, builder: (BuildContext context) => addClientDialog(settings, 2, ));
          },
          child: const Icon(Icons.add, color: Colors.white,)),
      )
    );
  }


  AlertDialog addClientDialog(MySettings settings, int index, {int? clientId}) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          index == 2 ? Text(AppLocalizations.of(context).translate("add_card")) : Text(AppLocalizations.of(context).translate("edit")),
          InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.cancel)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: TextFormField(
                    validator: (val) {
                      final digitsOnly = val?.replaceAll(' ', '') ?? '';
                      if (digitsOnly.length != 16) {
                        return AppLocalizations.of(context).translate("must_be_16");
                      }
                      if (val == "") {
                        return AppLocalizations.of(context).translate("enter_card_number");
                      }
                      return null;
                    },
                    controller: panController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CardNumberInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      suffixIcon: IconButton(onPressed: (){
                        panController.clear();
                      }, icon: const Icon(Icons.clear)),
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("enter_card_number"),
                      focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                      enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey2,
                  child: TextFormField(
                    controller: expiryController,
                    keyboardType: TextInputType.number,
                    validator: validateExpiryDate,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ExpiryDateInputFormatter(),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).translate("expire_date_hint"),
                      suffixIcon: IconButton(onPressed: (){
                        expiryController.clear();
                      }, icon: const Icon(Icons.clear)),
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("enter_card_expiry"),
                      focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                      enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey3,
                  child: TextFormField(
                    validator: (val){
                      if(val == ""){
                        return AppLocalizations.of(context).translate("enter_card_name");
                      }
                      return null;
                    },
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(onPressed: (){
                        nameController.clear();
                      }, icon: const Icon(Icons.clear)),
                      isDense: true,
                      fillColor: Colors.grey.shade200,
                      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red),borderRadius: BorderRadius.circular(10)),
                      labelText: AppLocalizations.of(context).translate("enter_card_name"),
                      focusColor: Theme.of(context).brightness == Brightness.light ? Colors.blue : Colors.blue,
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue),borderRadius: BorderRadius.circular(10)),
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                      enabledBorder:  OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(MediaQuery.of(context).size.width, 45),
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          if (!_formKey2.currentState!.validate()) {
                            return;
                          }
                          if (!_formKey3.currentState!.validate()) {
                            return;
                          }
            
                          final cleanedCardNumber = panController.text.replaceAll(' ', '');
                          final cleanedExpiry = expiryController.text.replaceAll('/', '');
                          await addCard(settings, cleanedCardNumber, cleanedExpiry);
            
                        }, child: Text(AppLocalizations.of(context).translate("profile_save")))
                ),
              ],
            ),
          ),
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

  Future<void> getAllCards(MySettings settings) async {

    if (_isLoading) return;
    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName())??"";

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
      cards = cardsData.map((item) => BankCardsModel.fromMapObject(item)).toList();
      if(mounted){
        setState(() {
          _isLoading = false;
        });

      }
    }
  }

  Future<void> deleteCard(MySettings settings, String pan) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/cards-delete");

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
        "pan": pan,
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      getAllCards(settings);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

  Future<void> addCard(MySettings settings, String cleanedCardNumber, String cleanedExpiry ) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/cards-add");

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
        "name": nameController.text,
        "pan": cleanedCardNumber,
        "expiry": cleanedExpiry
      }),
    );

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
      if (data != null && data["e"] != null && data["e"]["code"] == "ER_DUP_ENTRY") {
        showRedSnackBar(AppLocalizations.of(context).translate("card_already_added"));
        return;
      }

      if (kDebugMode) {
        debugPrint("Error data null or data['ok] != 1");
      }
      return;
    }

    if (data["ok"] == 1) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      getAllCards(settings);
      nameController.clear();
      panController.clear();
      expiryController.clear();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }


  Future<void> editClient(MySettings settings, int id) async {
    String fcmToken = await Utils.getToken();

    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-edit");

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
        "id": id,
        "name": nameController.text,
        "phone": panController.text,
        "psw": expiryController.text
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      getAllCards(settings);
      nameController.clear();
      panController.clear();
      expiryController.clear();
      Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

  final images = [
    "assets/images/blue_card.png",
    "assets/images/card_backgr.png",
    "assets/images/bank_background.jpg",
    "assets/images/backgroundimage.png",
  ];

  Widget _buildNotFoundWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          Text("${AppLocalizations.of(context).translate("list_empty")} :(", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    );
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

