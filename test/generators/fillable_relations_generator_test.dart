import 'package:build/build.dart';
import 'package:bavard/src/generators/model_fillable_generator.dart';
import 'package:test/test.dart';
import 'package:build_test/build_test.dart';

const _sourceWithRelations = '''
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/src/generators/annotations.dart';

part 'source.fillable.g.dart';

@fillable
class User extends Model with \$UserFillable {
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
  );

  User([super.attributes]);

  @override
  String get table => 'users';

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts() => hasMany(Post.new);

  BelongsTo<Post> get favorite => belongsTo(Post.new);

  MorphTo<Model> commentable() =>
      morphToTyped('commentable', {'posts': Post.new});

  @override
  Relation? getRelation(String name) {
    return super.getRelation(name);
  }
}

class Post extends Model {
  @override
  String get table => 'posts';

  Post([super.attributes]);

  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);
}
''';

const _sourceWithoutRelations = '''
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/src/generators/annotations.dart';

part 'source.fillable.g.dart';

@fillable
class Product extends Model with \$ProductFillable {
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
  );

  Product([super.attributes]);

  @override
  String get table => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) => Product(map);
}
''';

const _sourceWithParameterizedRelation = '''
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/src/generators/annotations.dart';

part 'source.fillable.g.dart';

@fillable
class User extends Model with \$UserFillable {
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
  );

  User([super.attributes]);

  @override
  String get table => 'users';

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts(int limit) => hasMany(Post.new).limit(limit);
}

class Post extends Model {
  @override
  String get table => 'posts';

  Post([super.attributes]);

  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);
}
''';

void main() {
  final outputAsset = AssetId.parse('pkg|lib/source.fillable.g.part');

  Future<TestBuilderResult> build(String source) async {
    final readerWriter = TestReaderWriter(rootPackage: 'pkg');
    await readerWriter.testing.loadIsolateSources();
    return testBuilder(fillableGenerator(BuilderOptions.empty), {
      'pkg|lib/source.dart': source,
    }, readerWriter: readerWriter);
  }

  /// Reads the hidden shared-part output written by the builder.
  Future<String> readOutput(TestBuilderResult result) async {
    final readerWriter = result.readerWriter as dynamic;
    return await readerWriter.readAsString(outputAsset, hidden: true);
  }

  group('FillableGenerator relation discovery', () {
    test('generates getRelation dispatch for methods and getters', () async {
      final result = await build(_sourceWithRelations);

      expect(result.outputs, contains(outputAsset));
      final output = await readOutput(result);

      // Abstract declarations for the relation members.
      expect(output, contains('HasMany<Post> posts();'));
      expect(output, contains('BelongsTo<Post> get favorite;'));
      expect(output, contains('MorphTo<Model> commentable();'));

      // Dispatch switch.
      expect(output, contains('Relation? getRelation(String name)'));
      expect(output, contains("case 'posts':"));
      expect(output, contains('return posts();'));
      expect(output, contains("case 'favorite':"));
      expect(output, contains('return favorite;'));
      expect(output, contains("case 'commentable':"));
      expect(output, contains('return commentable();'));
      expect(output, contains('return super.getRelation(name);'));
    });

    test('does not emit getRelation when the model has no relations', () async {
      final result = await build(_sourceWithoutRelations);

      expect(result.outputs, contains(outputAsset));
      final output = await readOutput(result);
      expect(output, isNot(contains('getRelation(String name)')));
      expect(output, contains("List<String> get fillable"));
    });

    test(
      'fails with an explicit error for parameterized relation methods',
      () async {
        final result = await build(_sourceWithParameterizedRelation);

        expect(result.outputs, isNot(contains(outputAsset)));
        expect(result.succeeded, isFalse);
        expect(
          result.errors.join('\n'),
          contains('Relation method "posts" has required parameters'),
        );
      },
    );
  });
}
