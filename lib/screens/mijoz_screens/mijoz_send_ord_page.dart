import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/models/payed_order_model.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
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
  double totalSumm = 0;
  bool isSending = false;
  File? selectedImage1;
  File? selectedImage2;

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
              Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(settings.clientName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(settings.payInfo, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400)),
                            IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: settings.payInfo));
                                  showSuccessSnackBar(AppLocalizations.of(context).translate("gl_successfully_copied"));
                                },
                                icon: const Icon(Icons.copy, color: Colors.white,))
                          ],
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context).translate("pin_cheque"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {

                      pickScreenshot(settings, 1);
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.width * 0.5,
                      width: selectedImage1 != null ? MediaQuery.of(context).size.width * 0.4 : MediaQuery.of(context).size.width * 0.9,
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
                                if (selectedImage1 == null) {
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

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }


  void sendOrder(MySettings settings) async {

    setState(() => isSending = true);

    try {
      final uploadTasks = <Future<String?>>[
        sendToTelegramAndGetFileId(settings, selectedImage1!),
        if (selectedImage2 != null) sendToTelegramAndGetFileId(settings, selectedImage2!),
      ];

      final results = await Future.wait(uploadTasks);

      final fileId1 = results[0];
      if (fileId1 == null) {
        showRedSnackBar("Rasmni yuborishda xatolik. Qayta urinib ko'ring.");
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
          showSuccessSnackBar(AppLocalizations.of(context).translate("sent_ord"));
          Navigator.pop(context);
        } else {
          showRedSnackBar(AppLocalizations.of(context).translate("error"));
        }
      } else {
        showRedSnackBar("Server xatoligi: ${response.statusCode}");
      }
    } catch (e) {
      if (context.mounted) {
        showRedSnackBar("Error: $e");
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