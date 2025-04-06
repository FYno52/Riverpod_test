import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// アプリ全体でRiverpodを利用するためにProviderScopeでラップ
void main() {
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

  // 状態更新用のcopyWithメソッド
  Todo copyWith({String? id, String? title, bool? completed}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// StateNotifierでTodoリストの状態を管理
class TodoListNotifier extends StateNotifier<List<Todo>> {
  TodoListNotifier() : super([]);

  // Todoの追加
  void addTodo(String title) {
    final todo = Todo(
      id: DateTime.now().toIso8601String(),
      title: title,
    );
    state = [...state, todo];
  }

  // Todoの完了/未完了を切り替え
  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(completed: !todo.completed) else todo
    ];
  }

  // Todoの削除
  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

// StateNotifierProviderの定義
final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier();
});

// Todoリストの画面
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
    // ProviderからTodoリストを取得
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
