import 'package:flutter_djolis/services/utils.dart';

class DicBalance {
  late double dolg1;
  late double dolg2;

  DicBalance({
    required this.dolg1,
    required this.dolg2,
  });

  @override
  String toString() {
    return 'DicBalance{dolg1: $dolg1, dolg: $dolg2}';
  }

  factory DicBalance.fromJson(Map<String, dynamic> json) {
    return DicBalance(
        dolg1: json['dolg1'] ?? 0,
        dolg2: json['dolg']?? 0
    );
  }

  Map<String, dynamic> toMap() => {
        'dolg1': dolg1,
        'dolg2': dolg2,
      };

  Map<String, dynamic> toJson() => {
        'dolg1': dolg1,
        'dolg2': dolg2,
      };

  DicBalance.fromMapObject(Map<String, dynamic> map) {
    dolg1 = Utils.checkDouble(map['dolg1']);
    dolg2 = Utils.checkDouble(map['dolg2']);
  }
}
