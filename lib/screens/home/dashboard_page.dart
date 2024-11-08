import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_localizations.dart';
import '../../core/mysettings.dart';
import '../../services/data_service.dart';
import '../../services/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<MySettings>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.grey.shade200,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InfoContainer(
                        color: Colors.green.shade300,
                        text1: "${AppLocalizations.of(context).translate("cashback")}:",
                        text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.cashBack.toDouble())
                    ),
                    const SizedBox(width: 10),
                    InfoContainer(
                        color: Colors.red.shade200,
                        text1: "${AppLocalizations.of(context).translate("debt")}:",
                        text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.debt.toDouble())
                    ),
                    const SizedBox(width: 10),
                    InfoContainer(
                        color: Colors.orange.shade300,
                        text1: "${AppLocalizations.of(context).translate("credit_limit")}:",
                        text2: Utils.myNumFormat(Utils.numFormat0_00, DataService.creditLimit.toDouble())
                    ),
                  ],
                ),
              ),
            ),
            expandedHeight: 80,  // Adjust height as needed
          ),
        ],
      ),
    );
  }
}

class InfoContainer extends StatelessWidget {
  final String text1;
  final String text2;
  final Color color;
  const InfoContainer({
    super.key, required this.color, required this.text1, required this.text2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Text(maxLines: 1,text1, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(text2, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
