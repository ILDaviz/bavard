import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'db.dart';
import 'models/todo.dart';
import 'models/post.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    stderr.writeln(details.toString());
  };

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    print('Initialize FFI');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      print('Setting up database...');
      await setupDatabase();
      print('Database setup complete.');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, s) {
      print('Error setting up database: $e');
      print(s);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Initializing Database...'),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bavard Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  Future<void> _refreshTodos() async {
    setState(() => _isLoading = true);

        final todos = (await Todo().newQuery().orderBy('created_at', direction: 'desc').get()).cast<Todo>();

    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _addTodo(String title) async {
    final todo = Todo();
    todo.title = title;
    await todo.save();
    _refreshTodos();
  }

  Future<void> _toggleTodo(Todo todo) async {
    todo.isCompleted = !todo.isCompleted;
    await todo.save();
    _refreshTodos();
  }

  Future<void> _deleteTodo(Todo todo) async {
    await todo.delete();
    _refreshTodos();
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTodo(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bavard Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshTodos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
          ? const Center(child: Text('No tasks yet. Add one!'))
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (ctx, index) {
                final todo = _todos[index];
                return Dismissible(
                  key: Key(todo.id.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteTodo(todo),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) => _toggleTodo(todo),
                    ),
                    title: Text(
                      todo.title ?? '',
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (_) => TodoDetailPage(todo: todo)),
                       );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoDetailPage extends StatefulWidget {
  final Todo todo;

  const TodoDetailPage({super.key, required this.todo});

  @override
  State<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends State<TodoDetailPage> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() => _isLoading = true);
    final posts = (await widget.todo.posts.get()).cast<Post>();

    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }
  
  Future<void> _addPost(String content) async {
    final post = Post();
    post.content = content;
    post.title = 'Note ${DateTime.now().second}'; // Dummy title
    post.todoId = widget.todo.id as int;
    await post.save();
    _refreshPosts();
  }

  Future<void> _deletePost(Post post) async {
    await post.delete();
    _refreshPosts();
  }

  void _showAddPostDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter note content...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addPost(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo.title ?? 'Todo Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notes for this task:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? const Center(child: Text('No notes yet.'))
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (ctx, index) {
                          final post = _posts[index];
                          return ListTile(
                            title: Text(post.content ?? ''),
                            subtitle: Text(post.createdAt?.toString() ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deletePost(post),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}