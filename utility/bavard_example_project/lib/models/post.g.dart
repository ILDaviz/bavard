// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// FillableGenerator
// **************************************************************************

mixin $PostFillable on Model {
  /// FILLABLE
  @override
  List<String> get fillable => const ['title', 'content', 'todo_id'];

  /// GUARDED
  @override
  List<String> get guarded => const ['id', 'created_at', 'updated_at'];

  /// CASTS
  @override
  Map<String, dynamic> get casts => {
    'id': 'id',
    'title': 'string',
    'content': 'string',
    'todo_id': 'int',
    'created_at': 'datetime',
    'updated_at': 'datetime',
  };

  /// Accessor for [title] (DB: title)
  String get title {
    return getAttribute('title');
  }

  set title(String value) => setAttribute('title', value);

  /// Accessor for [content] (DB: content)
  String get content {
    return getAttribute('content');
  }

  set content(String value) => setAttribute('content', value);

  /// Accessor for [todoId] (DB: todo_id)
  int get todoId {
    return getAttribute('todo_id');
  }

  set todoId(int value) => setAttribute('todo_id', value);
}
