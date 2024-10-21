
import 'package:flutter/material.dart';
import 'package:flutter_djolis/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/mysettings.dart';

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key});

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
        child: Center(
          child: Text(AppLocalizations.of(context).translate("soon"), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
        ),
      ),
    );
  }


  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ));
  }
}





