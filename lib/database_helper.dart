import 'package:riverpod_test/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TodoDatabase {
  static final TodoDatabase instance = TodoDatabase._init();

  static Database? _database;

  TodoDatabase._init();

//データベースが初期化されているかを確認
//初期化されていない場合、_initDB メソッドを呼んで新たにデータベースを作成
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

// データベースの初期化・作成
// データベースが保存されるディレクトリパスを取得し、join を使ってファイルパス（ここでは "todo.db"）を作成
// openDatabase を呼び出し、バージョンや初回作成時のコールバック（onCreate）を設定
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

// テーブルの作成
// SQLの CREATE TABLE 文を実行して、各カラムのデータ型や制約を定義
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE todos (
      id $idType,
      title $textType,
      completed $boolType
    )
    ''');
  }

// CRUD操作の実装

// オブジェクトをMap形式に変換（toMap()）し、db.insert()を用いてtodosテーブルに新しい行として挿入
// ConflictAlgorithm.replace を指定して、同じIDのレコードが存在する場合は上書き
  Future<void> insertTodo(Todo todo) async {
    final db = await instance.database;
    await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// db.query('todos')でテーブル内の全データを取得し、取得したMapのリストをTodo.fromMap() を使ってTodoオブジェクトのリストに変換
  Future<List<Todo>> getTodos() async {
    final db = await instance.database;
    final maps = await db.query('todos');
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

// 既存の内容を更新するために、db.update()を利用
// 更新するレコードはwhere: 'id = ?' と whereArgs: [todo.id]で特定され、Mapに変換した新しいデータで上書き
  Future<void> updateTodo(Todo todo) async {
    final db = await instance.database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

// 指定されたIDのTodoを削除するために、db.delete() を使用
  Future<void> deleteTodo(String id) async {
    final db = await instance.database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
