abstract class MyTable {
  MyTable();

  Map<String, dynamic> toMap();
  MyTable.fromMapObject(Map<String, dynamic> map);
  int getId();
  String getTableName();
}