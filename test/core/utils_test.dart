import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';

void main() {
  group('Utils Helper', () {
    test('singularize() handles standard plurals', () {
      expect(Utils.singularize('users'), 'user');
      expect(Utils.singularize('posts'), 'post');
      expect(Utils.singularize('comments'), 'comment');
    });

    test('singularize() handles -ies suffix', () {
      expect(Utils.singularize('categories'), 'category');
      expect(Utils.singularize('countries'), 'country');
      expect(Utils.singularize('companies'), 'company');
    });

    test('singularize() handles words ending in s but not plural', () {
      expect(Utils.singularize('process'), 'process');
      expect(Utils.singularize('status'), 'statu');
    });

    test('foreignKey() generates correct snake_case keys', () {
      expect(Utils.foreignKey('users'), 'user_id');
      expect(Utils.foreignKey('categories'), 'category_id');
      expect(Utils.foreignKey('user_roles'), 'user_role_id');
    });
  });
  group('Utils.singularize', () {
    test('handles regular plurals', () {
      expect(Utils.singularize('users'), 'user');
      expect(Utils.singularize('posts'), 'post');
      expect(Utils.singularize('comments'), 'comment');
      expect(Utils.singularize('profiles'), 'profile');
    });

    test('handles -ies suffix', () {
      expect(Utils.singularize('categories'), 'category');
      expect(Utils.singularize('countries'), 'country');
      expect(Utils.singularize('companies'), 'company');
      expect(Utils.singularize('cities'), 'city');
    });

    test('handles -es suffix for certain words', () {
      expect(Utils.singularize('boxes'), 'boxe'); // Simple implementation
      expect(Utils.singularize('watches'), 'watche');
    });

    test('handles already singular words', () {
      expect(Utils.singularize('user'), 'user');
      expect(Utils.singularize('post'), 'post');
      expect(Utils.singularize('data'), 'data');
    });

    test('handles empty string', () {
      expect(Utils.singularize(''), '');
    });

    test('handles single character', () {
      expect(Utils.singularize('s'), '');
      expect(Utils.singularize('a'), 'a');
    });

    test('handles words ending in ss (not plural)', () {
      expect(Utils.singularize('process'), 'process');
      expect(Utils.singularize('class'), 'class');
      expect(Utils.singularize('address'), 'address');
    });
  });

  group('Utils.foreignKey', () {
    test('with single word table', () {
      expect(Utils.foreignKey('users'), 'user_id');
      expect(Utils.foreignKey('posts'), 'post_id');
    });

    test('with multi-word table', () {
      expect(Utils.foreignKey('user_roles'), 'user_role_id');
      expect(Utils.foreignKey('blog_posts'), 'blog_post_id');
    });

    test('with already singular name', () {
      expect(Utils.foreignKey('user'), 'user_id');
      expect(Utils.foreignKey('post'), 'post_id');
    });

    test('with -ies plural', () {
      expect(Utils.foreignKey('categories'), 'category_id');
      expect(Utils.foreignKey('countries'), 'country_id');
    });
  });
}
