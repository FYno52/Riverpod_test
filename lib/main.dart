import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_test/database_helper.dart';

// アプリ全体でRiverpodを利用するためにProviderScopeでラップ
void main() {
  // アプリ全体でRiverpodの状態管理を利用するため、main()でProviderScopeでMyAppをラップ
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App with Riverpod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListPage(),
    );
  }
}

// Todoモデルクラス
class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });

  //※ SQLiteではオブジェクトを保存する際、Map形式（キーと値）に変換する必要がある
  // Map形式に変換（SQLiteのINSERTやUPDATEで利用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0, // SQLiteには数値で保存
    };
  }

  // MapからTodoインスタンスを生成
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      completed: map['completed'] == 1,
    );
  }

  // 状態更新用のcopyWithメソッド 状態変更時に新しいインスタンスを生成
  Todo copyWith({String? id, String? title, bool? completed}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// StateNotifierでTodoリストの状態を管理
// Todoの追加・状態切替・削除のロジックを実装し、StateNotifierProviderでプロバイダーとして公開
// データベースからタスクを読み込み、追加・更新・削除の際にSQLiteへ反映する
class TodoListNotifier extends StateNotifier<List<Todo>> {
  TodoListNotifier() : super([]) {
    _init();
  }

  // DBから既存のTodoを読み込む
  Future<void> _init() async {
    final todos = await TodoDatabase.instance.getTodos();
    state = todos;
  }

  // Todoの追加
  Future<void> addTodo(String title) async {
    final todo = Todo(
      id: DateTime.now().toIso8601String(),
      title: title,
    );
    await TodoDatabase.instance.insertTodo(todo);
    state = [...state, todo];
  }

  // Todoの完了/未完了の切り替え
  Future<void> toggleTodo(String id) async {
    state = await Future.wait(state.map((todo) async {
      if (todo.id == id) {
        final newTodo = todo.copyWith(completed: !todo.completed);
        await TodoDatabase.instance.updateTodo(newTodo);
        return newTodo;
      }
      return todo;
    }));
  }

  // Todoの削除
  Future<void> removeTodo(String id) async {
    await TodoDatabase.instance.deleteTodo(id);
    state = state.where((todo) => todo.id != id).toList();
  }
}

// StateNotifierProviderの定義
final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier();
});

// Todoリストの画面 ref.watch(todoListProvider)で現在のTodoリストを取得
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ProviderからTodoリストを取得 ref.watch(todoListProvider)で現在のリストを取得
    final todos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Todo App")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                // 新しいTodoの入力フィールド
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "New Todo",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Todo追加ボタン
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      ref
                          .read(todoListProvider.notifier)
                          .addTodo(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: Text("Add"),
                )
              ],
            ),
          ),
          // Todoリストの表示
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return ListTile(
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  // チェックボックスで完了状態の切り替え
                  leading: Checkbox(
                    value: todo.completed,
                    onChanged: (value) {
                      ref.read(todoListProvider.notifier).toggleTodo(todo.id);
                    },
                  ),
                  // 削除ボタン
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      ref.read(todoListProvider.notifier).removeTodo(todo.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
