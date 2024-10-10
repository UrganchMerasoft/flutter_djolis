import 'package:flutter/material.dart';
import 'package:flutter_djolis/models/dic_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PayQRPage extends StatefulWidget {
  final String title;
  final String qr;
  final DicCardModel card;
  const PayQRPage(this.title, this.qr, this.card, {super.key});

  @override
  State<PayQRPage> createState() => _PayQRPageState();
}

class _PayQRPageState extends State<PayQRPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(child: Padding(padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 32,),
            Text(widget.card.card_num, style: Theme.of(context).textTheme.titleLarge,),
            SizedBox(height: 16,),
            Center(
              child: QrImageView(
                data: widget.qr,
                version: QrVersions.auto,
                size: 200.0,
              ),),
            SizedBox(height: 16,),
            Text(widget.card.name, style: Theme.of(context).textTheme.titleLarge,),
          ],
        ),),),
    );
  }
}
