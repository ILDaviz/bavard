# Bavard ORM

> [!CAUTION]
> **This project is under active development. APIs and documentation may change.**

**A Eloquent-inspired ORM for Dart/Flutter**

Bavard is an Object-Relational Mapping library that brings the Active Record pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home. The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

# Example Model:

```dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'vehicle.dart';
import 'trip.dart';
import 'user.fillable.g.dart';

@fillable
class User extends Model with $UserFillable, HasUuids {
  @override
  String get table => 'users';

  static const schema = (
    name: TextColumn('name'),
    email: TextColumn('email'),
    timezone: TextColumn('timezone'),
    createdAt: DateTimeColumn('created_at'),
    updatedAt: DateTimeColumn('updated_at'),
  );

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts() => hasMany(Post.new);
  List<Post> get postsList => getRelationList<Post>('posts');

  HasMany<Image> images() => hasMany(Image.new);
  List<Image> get imagesList => getRelationList<Image>('images');

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    if (name == 'images') return images();
    return super.getRelation(name);
  }
}
```
