// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// FillableGenerator
// **************************************************************************

mixin $UserFillable on Model {
  /// FILLABLE
  @override
  List<String> get fillable => const ['name', 'email'];

  /// GUARDED
  @override
  List<String> get guarded => const ['id', 'created_at', 'updated_at'];

  /// CASTS
  @override
  Map<String, dynamic> get casts => {
    'id': 'id',
    'name': 'string',
    'email': 'string',
    'created_at': 'datetime',
    'updated_at': 'datetime',
  };

  /// Accessor for [name] (DB: name)
  String get name {
    return getAttribute('name');
  }

  set name(String value) => setAttribute('name', value);

  /// Accessor for [email] (DB: email)
  String get email {
    return getAttribute('email');
  }

  set email(String value) => setAttribute('email', value);
}
