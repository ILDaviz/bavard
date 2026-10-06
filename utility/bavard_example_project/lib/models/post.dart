import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'todo.dart';

part 'post.g.dart';

@fillable
class Post extends Model with HasTimestamps, $PostFillable {
  static const schema = (
    id: IdColumn(),
    title: TextColumn('title'),
    content: TextColumn('content'),
    todoId: IntColumn('todo_id'),
    createdAt: CreatedAtColumn(),
    updatedAt: UpdatedAtColumn(),
  );

  Post([super.attributes]);

  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  @override
  String get table => 'posts';

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'todo':
        return todo;
      default:
        return super.getRelation(name);
    }
  }

  BelongsTo<Todo> get todo => belongsTo<Todo>(Todo.new);
}