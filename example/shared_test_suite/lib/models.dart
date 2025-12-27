import 'dart:convert';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

// ==========================================
// MODELS (With Dispatcher)
// ==========================================

class Address {
  final String street;
  final String city;

  Address(this.street, this.city);

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(json['street'], json['city']);
  }

  Map<String, dynamic> toJson() => {'street': street, 'city': city};

  @override
  String toString() => '$street, $city';
}

class AddressCast implements AttributeCast<Address, String> {
  @override
  Address get(String rawValue, Map<String, dynamic> attributes) {
    return Address.fromJson(jsonDecode(rawValue));
  }

  @override
  String set(Address value, Map<String, dynamic> attributes) {
    return jsonEncode(value.toJson());
  }
}

class User extends Model with HasTimestamps {
  @override
  String get table => 'users';

  @override
  List<SchemaColumn> get columns => [
    IdColumn(),
    TextColumn('name'),
    TextColumn('email'),
    // Address handled by custom cast
    // Avatar handled raw
    CreatedAtColumn(),
    UpdatedAtColumn(),
  ];

  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasOne<Profile> profile() => hasOne(Profile.new);
  HasMany<Post> posts() => hasMany(Post.new);
  HasMany<Comment> comments() => hasMany(Comment.new);
  HasManyThrough<Comment, Post> postComments() {
    return hasManyThroughPolymorphic(
      Comment.new,
      Post.new,
      name: 'commentable',
      type: 'posts',
    );
  }

  @override
  Map<String, dynamic> get casts => {
    'address': AddressCast(),
  };

  Address? get address => getAttribute<Address>('address');
  set address(Address? value) => setAttribute('address', value);

  List<int>? get avatar => getAttribute<List<int>>('avatar');
  set avatar(List<int>? value) => setAttribute('avatar', value);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'profile':
        return profile();
      case 'posts':
        return posts();
      case 'comments':
        return comments();
      case 'postComments':
        return postComments();
      default:
        return super.getRelation(name);
    }
  }
}

class Profile extends Model with HasTimestamps {
  @override
  String get table => 'profiles';
  Profile([super.attributes]);
  @override
  Profile fromMap(Map<String, dynamic> map) => Profile(map);

  BelongsTo<User> user() => belongsTo(User.new);

  @override
  Relation? getRelation(String name) {
    return name == 'user' ? user() : null;
  }
}

class Post extends Model with HasTimestamps {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  BelongsTo<User> author() => belongsTo(User.new, foreignKey: 'user_id');

  BelongsToMany<Category> categories() {
    return belongsToMany(
      Category.new,
      'category_post',
    ).withPivot(['created_at']);
  }

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'author':
        return author();
      case 'categories':
        return categories();
      case 'comments':
        return comments();
      default:
        return super.getRelation(name);
    }
  }
}

class Category extends Model with HasTimestamps {
  @override
  String get table => 'categories';
  Category([super.attributes]);
  @override
  Category fromMap(Map<String, dynamic> map) => Category(map);

  BelongsToMany<Post> posts() => belongsToMany(Post.new, 'category_post');

  @override
  Relation? getRelation(String name) {
    return name == 'posts' ? posts() : null;
  }
}

class Video extends Model with HasTimestamps {
  @override
  String get table => 'videos';
  Video([super.attributes]);
  @override
  Video fromMap(Map<String, dynamic> map) => Video(map);

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');

  @override
  Relation? getRelation(String name) {
    return name == 'comments' ? comments() : null;
  }
}

class Comment extends Model with HasTimestamps {
  @override
  String get table => 'comments';
  Comment([super.attributes]);
  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);

  MorphTo<Model> commentable() =>
      morphToTyped('commentable', {'posts': Post.new, 'videos': Video.new});
  BelongsTo<User> author() => belongsTo(User.new);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'commentable':
        return commentable();
      case 'author':
        return author();
      default:
        return super.getRelation(name);
    }
  }
}

class Task extends Model with HasTimestamps, HasSoftDeletes {
  @override
  String get table => 'tasks';

  Task([super.attributes]);

  @override
  Task fromMap(Map<String, dynamic> map) => Task(map);

  @override
  Map<String, String> get casts => {'metadata': 'json'};
}

class Product extends Model with HasTimestamps {
  @override
  String get table => 'products';
  Product([super.attributes]);
  @override
  Product fromMap(Map<String, dynamic> map) => Product(map);

  @override
  Future<bool> onSaving() async {
    if (attributes.containsKey('name')) {
      attributes['name'] = attributes['name'].toString().toUpperCase();
    }

    return true;
  }
}
