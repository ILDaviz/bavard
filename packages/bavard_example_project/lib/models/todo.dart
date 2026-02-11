import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'post.dart';

part 'todo.g.dart';

@fillable
class Todo extends Model with HasTimestamps, $TodoFillable {
  static const schema = (
    id: IdColumn(),
    title: TextColumn('title'),
    isCompleted: BoolColumn('is_completed'),
    createdAt: CreatedAtColumn(),
    updatedAt: UpdatedAtColumn(),
  );

  Todo([super.attributes]);

  @override
  String get table => 'todos';

  @override
  Todo fromMap(Map<String, dynamic> map) => Todo(map);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'posts':
        return posts;
      default:
        return super.getRelation(name);
    }
  }

  HasMany<Post> get posts => hasMany<Post>(Post.new);
}