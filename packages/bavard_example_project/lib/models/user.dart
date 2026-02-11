import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'post.dart';

part 'user.g.dart';

@fillable
class User extends Model with HasTimestamps, $UserFillable {
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
    email: TextColumn('email'),
    createdAt: CreatedAtColumn(),
    updatedAt: UpdatedAtColumn(),
  );

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  @override
  String get table => 'users';

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
