import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Owers());
}

class OwersStorage {
  String url = "";
  var fileName;
  File? file;

  Future<Database> initialDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    return openDatabase(
      join(await getDatabasesPath(), 'owers_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE owers(name TEXT PRIMARY KEY, debt DOUBLE)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Виконай SQL-запит для створення нової таблиці
          await db.execute(
            'CREATE TABLE нова_таблиця(id INTEGER PRIMARY KEY, назва TEXT, кількість DOUBLE)',
          );
        }
        // Додай інші умови для майбутніх версій
      },
      version: 2,
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await initialDB();
    try {
      await db.delete("owers", where: "name = ?", whereArgs: [id]);
      await getfile("deleteOwer/owers_database.db");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  Future<void> insertOwer(OwersRowData data) async {
    final db = await initialDB();
    await db.insert(
      'owers',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await getfile("insertOwer/owers_database.db");
  }

  Future<List<OwersRowData>> getItems() async {
    final db = await initialDB();
    final List<Map<String, Object?>> queryResult =
        await db.query('owers', orderBy: "name");
    return queryResult.map((e) => OwersRowData.fromMap(e)).toList();
  }

  Future<void> updateOwer(OwersRowData data) async {
    final db = await initialDB();

    await db.update(
      'owers',
      data.toMap(),
      where: 'name = ?',
      whereArgs: [data.name],
    );
    await getfile("updateDatabase/owers_database.db");
  }

  getfile(String path) async {
    File c =
        File("/data/data/com.example.owerlist/databases/owers_database.db");
    file = c;
    uploadFile(path);
  }

  uploadFile(String path) async {
    try {
      var imagefile = FirebaseStorage.instance
          .ref()
          .child("Users")
          .child(path);
      UploadTask task = imagefile.putFile(file!);
      TaskSnapshot snapshot = await task;
      url = await snapshot.ref.getDownloadURL();
      print(url);
      if (url != null && file != null) {
        Fluttertoast.showToast(
          msg: "Done Uploaded",
          textColor: Colors.red,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Something went wrong",
          textColor: Colors.red,
        );
      }
    } on Exception catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        textColor: Colors.red,
      );
    }
  }
}

List<OwersRowData> listRow = [];
List<OwersRowData> searchList = [];

class Owers extends StatefulWidget {
  Owers({Key? key}) : super(key: key);

  @override
  _OwersState createState() => _OwersState();
}

class _OwersState extends State<Owers> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Боржники",
          ),
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Search(),
                AddOwer(),
                _OwersList(listRow: searchList)
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshNotes() async {
    OwersStorage storage = OwersStorage();
    final data = await storage.getItems();
    listRow = data;
    if (searchList.isEmpty) {
      searchList.addAll(listRow);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }
}

class OwersRowData {
  String name;
  double debt;

  OwersRowData(this.name, this.debt);

  OwersRowData.fromMap(Map<String, dynamic> item)
      : name = item["name"],
        debt = item["debt"];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'debt': debt,
    };
  }

  @override
  String toString() {
    return 'Ower{name: $name, debt: $debt}';
  }
}

class _OwersList extends StatelessWidget {
  final List<OwersRowData> listRow;

  const _OwersList({
    Key? key,
    required this.listRow,
  }) : super(key: key);

  @override
  Widget build(BuildContext) {
    return Container(
      color: Colors.white,
      child: Column(
        children: listRow.map((data) => _OwersListRow(data: data)).toList(),
      ),
    );
  }
}

class AddOwer extends StatefulWidget {
  AddOwer({
    Key? key,
  }) : super(key: key);

  @override
  _AddOwerState createState() => new _AddOwerState();
}

class _AddOwerState extends State<AddOwer> {
  final nameController = TextEditingController();
  final debtController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(
                width: 120,
                child: Text("Прізвище", style: TextStyle(fontSize: 15))),
            Expanded(
              child: TextFormField(
                style: const TextStyle(fontSize: 20),
                controller: nameController,
                keyboardType: TextInputType.text,
                cursorHeight: 24,
              ),
            ),
            const SizedBox(
                width: 70, child: Text("Сума", style: TextStyle(fontSize: 15))),
            Expanded(
              child: TextFormField(
                style: const TextStyle(fontSize: 20),
                controller: debtController,
                keyboardType: TextInputType.number,
                cursorHeight: 23,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  OwersStorage storage = OwersStorage();
                  searchList.add(OwersRowData(
                      nameController.text, double.parse(debtController.text)));
                  listRow.add(OwersRowData(
                      nameController.text, double.parse(debtController.text)));
                  storage.insertOwer(OwersRowData(
                      nameController.text, double.parse(debtController.text)));
                  Navigator.of(context).popAndPushNamed("/");
                });
              },
              child: const Text('+', style: TextStyle(fontSize: 30),),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.orangeAccent),
              ),
            ),
          ],
        ));
  }
}

class _OwersListRow extends StatelessWidget {
  final OwersRowData data;

  _OwersListRow({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
              onPressed: () {
                if (data.debt == 0) {
                  OwersStorage storage = OwersStorage();
                  storage.deleteItem(data.name);
                  searchList.remove(data);
                  listRow.remove(data);
                  Navigator.of(context).popAndPushNamed("/");
                }
              },
              icon: Icon(Icons.delete)),
          SizedBox(
            width: 230,
            child: Text(
              data.name,
              style: const TextStyle(fontSize: 17),
            ),
          ),
          DataDebt(data: data),
        ],
      ),
    );
  }
}

class DataDebt extends StatefulWidget {
  DataDebt({Key? key, required this.data}) : super(key: key);
  OwersRowData data;

  @override
  _DataDebtState createState() => new _DataDebtState(data: data);
}

class _DataDebtState extends State<DataDebt> {
  final myController = TextEditingController();
  final OwersRowData data;
  OwersStorage storage = OwersStorage();

  _DataDebtState({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 100,
          child:
              Text(data.debt.toString(), style: const TextStyle(fontSize: 18)),
        ),
        Expanded(
          child: TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                _showToast(context);
              }
              return null;
            },
            style: const TextStyle(fontSize: 20),
            controller: myController,
            keyboardType: TextInputType.number,
            cursorHeight: 24,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              data.debt += double.parse(myController.text);
              storage.updateOwer(OwersRowData(data.name, data.debt));
              myController.text = "";
            });
          },
          child: const Text('ОК', style: TextStyle(fontSize: 20),),

        ),
      ],
    ));
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Введіть хоч шось'),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}

//Пошук
class Search extends StatefulWidget {
  Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => new _SearchState();
}

class _SearchState extends State<Search> {
  final nameController = TextEditingController();
  List<OwersRowData> list = [];

  void searchItems(String item) {
    searchList.removeRange(0, searchList.length);
    for (var Item in listRow) {
      if (Item.name.toLowerCase().contains(item.toLowerCase())) {
        list.add(Item);
      }
    }
    print("SEARCH SEARCH SEARCH");
    searchList.addAll(list);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  _showToast(context, 'Введіть прізвище');
                }
                return null;
              },
              style: const TextStyle(fontSize: 25),
              controller: nameController,
              keyboardType: TextInputType.text,
              cursorHeight: 25,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                searchItems(nameController.text);
                Navigator.of(context).popAndPushNamed("/");
              });
            },
            icon: const Icon(Icons.search),
          )
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String mes) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(mes),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
