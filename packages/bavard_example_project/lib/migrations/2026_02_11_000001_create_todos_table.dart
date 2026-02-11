import 'package:bavard_migration/bavard_migration.dart';

class CreateTodosTable extends Migration {
  @override
  Future<void> up(Schema schema) async {
    await schema.create('todos', (table) {
      table.id();
      table.string('title');
      table.boolean('is_completed').nullable().defaultTo(false);
      table.timestamps();
    });
  }

  @override
  Future<void> down(Schema schema) async {
    await schema.dropIfExists('todos');
  }
}
