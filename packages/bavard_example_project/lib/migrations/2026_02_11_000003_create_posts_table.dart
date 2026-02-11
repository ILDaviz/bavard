import 'package:bavard_migration/bavard_migration.dart';

class CreatePostsTable extends Migration {
  @override
  Future<void> up(Schema schema) async {
    await schema.create('posts', (table) {
      table.id();
      table.string('title');
      table.text('content');
      table.integer('todo_id');
      table.timestamps();
    });
  }

  @override
  Future<void> down(Schema schema) async {
    await schema.dropIfExists('posts');
  }
}
