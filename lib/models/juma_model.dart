import '../services/utils.dart';

class JumaModel {

  late int id;
  late int week_day;
  late String curdate;
  late String name;
  late double savdo_summ;
  late double summ;

  JumaModel({
   required this.id,
   required this.week_day,
   required this.curdate,
   required this.name,
   required this.savdo_summ,
   required this.summ,
  });


  @override
  String toString() {
    return 'JumaModel: id: $id, week_day: $week_day, curdate: $curdate, name: $name, savdo_summ: $savdo_summ, summ: $summ';
  }

  factory JumaModel.fromJson(Map<String, dynamic> json) {
    return JumaModel(
        id: json['id'] ?? 0,
        week_day: json['week_day'] ?? 0,
        curdate: json['curdate'] ?? '',
        name: json['name'] ?? '',
        savdo_summ: json['savdo_summ'] ?? 0,
        summ: json['summ'] ?? 0
    );
  }

  Map<String, dynamic> toMap()=>{
    'id':id,
    'week_day':week_day,
    'curdate':curdate,
    'name':name,
    'savdo_summ':savdo_summ,
    'summ':summ,
  };

  Map<String,dynamic> toJson(){
    return {
      'id':id,
      'week_day':week_day,
      'curdate':curdate,
      'name':name,
      'savdo_summ':savdo_summ,
      'summ':summ,
    };
  }

  JumaModel.fromMapObject(Map<String, dynamic> map) {
    id = map['id'] ?? 0;
    week_day = map['week_day'] ?? 0;
    curdate = map['curdate'] ?? '';
    name = map['name'] ?? '';
    savdo_summ = Utils.checkDouble(map['savdo_summ']);
    summ = Utils.checkDouble(map['summ']);
  }
}