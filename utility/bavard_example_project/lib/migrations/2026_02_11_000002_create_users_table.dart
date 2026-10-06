import 'package:bavard/bavard.dart';

class CreateUsersTable extends Migration {
  @override
  Future<void> up(Schema schema) async {
    await schema.create('users', (table) {
      table.id();
      table.string('name');
      table.string('email');
      table.timestamps();
    });
  }

  @override
  Future<void> down(Schema schema) async {
    await schema.dropIfExists('users');
  }
}
