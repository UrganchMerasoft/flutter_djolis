import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/mysettings.dart';
import '../../../models/dic_clients.dart';
import '../../../services/utils.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final FocusNode _searchFocusNode = FocusNode();
  List<DicClients> clients = [];
  List<DicClients> filteredClients = [];
  bool _isSearching = false;
  bool _isLoading = false;

  final TextEditingController searchController = TextEditingController();
  String _searchQuery = "";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pswController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<MySettings>(context, listen: false);
      getAllClients(settings);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    pswController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
    // keyingi frame’da fokus beramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(FocusNode()); // eski fokusni tozalash
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = "";
      searchController.clear();
      filteredClients = List.from(clients);
    });
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      filteredClients = List.from(clients);
      return;
    }

    final q = _searchQuery.toLowerCase().trim();

    filteredClients = clients.where((c) {
      final name = (c.name).toLowerCase();
      final phone = c.phone.toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isSearching
                            ? Container(
                          key: const ValueKey("search_field"),
                          height: 44,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: TextField(
                            onSubmitted: (_) {
                              _closeSearch();
                            },
                            focusNode: _searchFocusNode,
                            controller: searchController,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(onPressed: () {
                                _closeSearch();
                            }, icon: Icon(Icons.clear, color: Colors.white,)),
                              hintText: AppLocalizations.of(context).translate("gl_search"),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _searchQuery = v;
                                _applySearch();
                              });
                            },
                          ),
                        )
                            : Center(
                          key: const ValueKey("title_text"),
                          child: Text(
                            AppLocalizations.of(context).translate("clients"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Visibility(
                          visible: !_isSearching,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _openSearch();
                              },
                              icon: Icon(
                                _isSearching ? Icons.close : Icons.search,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: IconButton(
                            onPressed: () {
                              nameController.clear();
                              phoneController.clear();
                              pswController.clear();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => addClientDialog(settings, 2),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.015),


              // List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];

                      return InkWell(
                        onTap: () {
                          nameController.text = client.name;
                          phoneController.text = client.phone;
                          pswController.text = client.psw;

                          showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                addClientDialog(settings, 1, clientId: client.id),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Slidable(
                            endActionPane: ActionPane(
                              extentRatio: 0.20,
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  borderRadius: BorderRadius.circular(16),
                                  backgroundColor: Colors.green.withOpacity(0.8),
                                  icon: Icons.password_sharp,
                                  label: "Code",
                                  onPressed: (BuildContext context1) async {
                                    Future.delayed(const Duration(milliseconds: 200), () async {
                                      await generateCode(context, settings, client.id);
                                    });
                                  },
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                client.name,
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white, width: 1),
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: Theme.of(context).primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.white, width: 1),
                                              ),
                                              child: Icon(
                                                Icons.phone,
                                                color: Theme.of(context).primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              client.phone,
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
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

  Future<void> getAllClients(MySettings settings) async {
    if (_isLoading) return;

    String fcmToken = await Utils.getToken();
    String device_name = (await Utils.getDeviceName()) ?? "";

    setState(() {
      _isLoading = true;
    });

    Uri uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-get");
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (kDebugMode) {
        debugPrint("getAll Error 1: $e");
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error JSON.$e")));
      }
      return;
    }

    if (data == null || data["ok"] != 1) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (kDebugMode) {
        debugPrint("getAll 2 Error data null or data['ok] != 1");
      }
      return;
    }

    final List<dynamic> clientsData = data['d'] ?? [];

    if (mounted) {
      setState(() {
        clients = clientsData.map((item) => DicClients.fromMapObject(item)).toList();

        // Yangi qo‘shilganlar birinchi (id bo‘yicha)
        clients.sort((a, b) => b.id.compareTo(a.id));

        // Filtered init + mavjud searchni qayta qo‘llash
        filteredClients = List.from(clients);
        _applySearch();

        _isLoading = false;
      });
    }
  }

  AlertDialog addClientDialog(MySettings settings, int index, {int? clientId}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          index == 2
              ? Text(AppLocalizations.of(context).translate("add_client"))
              : Text(AppLocalizations.of(context).translate("edit")),
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.cancel),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () => nameController.clear(),
                    icon: const Icon(Icons.clear),
                  ),
                  isDense: true,
                  fillColor: Colors.grey.shade200,
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: AppLocalizations.of(context).translate("new_account_name"),
                  focusColor: Colors.blue,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () => phoneController.clear(),
                    icon: const Icon(Icons.clear),
                  ),
                  isDense: true,
                  fillColor: Colors.grey.shade200,
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: AppLocalizations.of(context).translate("new_account_phone"),
                  focusColor: Colors.blue,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Visibility(
                visible: false,
                child: TextFormField(
                  controller: pswController,
                  autofocus: true,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => pswController.clear(),
                      icon: const Icon(Icons.clear),
                    ),
                    isDense: true,
                    fillColor: Colors.grey.shade200,
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: AppLocalizations.of(context).translate("new_account_password"),
                    focusColor: Colors.blue,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.blue,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
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
                    if (nameController.text == "") {
                      showRedSnackBar(AppLocalizations.of(context).translate("profile_name_error"));
                      return;
                    }
                    if (phoneController.text == "") {
                      showRedSnackBar(AppLocalizations.of(context).translate("profile_phone_error"));
                      return;
                    }

                    if (index == 1 && clientId != null) {
                      await editClient(settings, clientId);
                    } else {
                      await addClient(settings);
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate("profile_save")),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showRedSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> addClient(MySettings settings) async {
    String fcmToken = await Utils.getToken();
    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-add");

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
        "phone": phoneController.text,
        "psw": "1",
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      await getAllClients(settings);

      nameController.clear();
      phoneController.clear();
      pswController.clear();

      if (mounted) Navigator.pop(context);
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
        "phone": phoneController.text,
        "psw": pswController.text,
      }),
    );

    if (res.statusCode == 200) {
      showSuccessSnackBar(AppLocalizations.of(context).translate("gl_success"));
      await getAllClients(settings);

      nameController.clear();
      phoneController.clear();
      pswController.clear();

      if (mounted) Navigator.pop(context);
    } else {
      debugPrint("Error: ${res.statusCode}");
      showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
    }
  }

  Future<void> generateCode(BuildContext context, MySettings settings, int id) async {
    String fcmToken = await Utils.getToken();
    final uri = Uri.parse("${settings.serverUrl}/api-djolis/mijoz-qr");

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
      body: jsonEncode({"id": id}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["ok"] == 1 && data["d"] != null) {
        String code = data["d"].toString();
        String formattedCode = "${code.substring(0, 3)} ${code.substring(3)}";

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).translate("code_for_login")),
              actionsPadding: const EdgeInsets.all(12),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedCode,
                      style: const TextStyle(letterSpacing: 5, fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        showSuccessSnackBar(AppLocalizations.of(context).translate("gl_successfully_copied"));
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      } else {
        debugPrint("Error: ${res.statusCode}");
        showRedSnackBar("${AppLocalizations.of(context).translate("unknown_error")}: ${res.statusCode}");
      }
    }
  }
}
