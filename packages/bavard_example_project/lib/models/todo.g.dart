// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// FillableGenerator
// **************************************************************************

mixin $TodoFillable on Model {
  /// FILLABLE
  @override
  List<String> get fillable => const ['title', 'is_completed'];

  /// GUARDED
  @override
  List<String> get guarded => const ['id', 'created_at', 'updated_at'];

  /// CASTS
  @override
  Map<String, dynamic> get casts => {
    'id': 'id',
    'title': 'string',
    'is_completed': 'bool',
    'created_at': 'datetime',
    'updated_at': 'datetime',
  };

  /// Accessor for [title] (DB: title)
  String get title {
    return getAttribute('title');
  }

  set title(String value) => setAttribute('title', value);

  /// Accessor for [isCompleted] (DB: is_completed)
  bool get isCompleted {
    return getAttribute('is_completed');
  }

  set isCompleted(bool value) => setAttribute('is_completed', value);
}
