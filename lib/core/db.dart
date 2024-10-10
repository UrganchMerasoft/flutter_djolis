import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/my_table.dart';

class DatabaseHelper {

  static DatabaseHelper? _databaseHelper;
  static Database? db;
  static String dbName = "";
  static int DB_VERSION = 1;

  DatabaseHelper._createInstance();

  factory DatabaseHelper() {
    _databaseHelper ??= DatabaseHelper._createInstance();
    return _databaseHelper!;
  }

  Future<Database> get database async {
    if (db == null) {
      db = await initializeDatabase();
      db!.execute("PRAGMA foreign_keys = ON");
    }
    return db!;
  }

  void closeDb() {
    db = null;
  }

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path.toString(), "$dbName.db");

    var myDatabase = openDatabase(path, version: DB_VERSION, onCreate: _createDb, onUpgrade: _upgrateDb);
    return myDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute("CREATE TABLE dic_cat (id INTEGER NOT NULL PRIMARY KEY, myUuid TEXT, name TEXT);");

    await db.execute("CREATE INDEX indActUuid ON doc_act_list (docUuid);");
  }

  void _upgrateDb(Database db, int oldVersion, int newVersion) async {
    // try {
    //   if (oldVersion<=2&&newVersion>=3) {
    //     await db.execute("CREATE INDEX indActUuid ON doc_act_list (docUuid);");
    //     await db.execute("CREATE INDEX indInvUuid ON doc_Inv_list (invUuid);");
    //     await db.execute("CREATE INDEX indOrdUuid ON doc_ord_list (ordUuid);");
    //   }
    //
    // } catch (_) { }
  }

  Future<Batch> getBatch() async {
    if (db == null) {
      db = await initializeDatabase();
      db!.execute("PRAGMA foreign_keys = ON");
    }
    return db!.batch();
  }

  Batch getBatchSync() {
    return db!.batch();
  }

  Future<int> rawUpdate(String sql) async {
    var db = await database;
    int result = await db.rawUpdate(sql);
    return result;
  }

  Future<int> deleteAllBySQL(String sql) async {
    var db = await database;
    int result = await db.rawDelete(sql);
    return result;
  }

  Future<int> insertTable(MyTable item) async {
    Database db = await database;
    var result = await db.insert(item.getTableName(), item.toMap());
    return result;
  }

  Future<int> updateTable(MyTable item) async {
    var db = await database;
    var result = await db.update(item.getTableName(), item.toMap(), where: 'id = ?', whereArgs: [item.getId()]);
    return result;
  }

  Future<int> deleteTable(MyTable item) async {
    var db = await database;
    int result = await db.rawDelete('DELETE FROM ${item.getTableName()} WHERE id = ${item.getId()}');
    return result;
  }

  Future<List<Map<String, dynamic>>> getMapList(String tableName, String order) async {
    Database db = await database;

    var result = await db.query(tableName, orderBy: order);
    return result;
  }

  Future<List<Map<String, dynamic>>> getRawMapList(String sql) async {
    Database db = await database;

    var result = await db.rawQuery(sql).catchError((e) {
      debugPrint(e.toString());
    });

    return result;
  }

  Future<List<String>> getListStringFromSql(String sql) async {
    Database db = await database;

    List<Map<String, Object?>> rawList = await db.rawQuery(sql).catchError((e) {
      //print(e.toString());
    });
    List<String> result = [];
    for (int i = 0; i < rawList.length; i++) {
      result.add(rawList[i]["name"].toString());
    }

    return result;
  }

  Future<int> getCount(String tableName) async {
    Database db = await database;
    List<Map<String, dynamic>> x = await db.rawQuery('SELECT COUNT(*) from $tableName');
    int result = Sqflite.firstIntValue(x)??0;
    return result;
  }

  Future<String?> getStringFromSQL(String sql) async {
    Database db = await database;
    List<Map<String, dynamic>> x = await db.rawQuery(sql);
    String? result;
    if (x.isNotEmpty) {
      result = x[0]["name"];
      }
    return result;
  }

  Future<int?> getIntFromSQL(String sql) async {
    Database db = await database;
    List<Map<String, dynamic>> x = await db.rawQuery(sql);
    int? result = Sqflite.firstIntValue(x);
    return result;
  }

  Future<double> getDoubleFromSQL(String sql) async {
    Database db = await database;
    List<Map<String, dynamic>> x = await db.rawQuery(sql);
    double result = x[0]["field1"] as double;
    return result;
  }

}