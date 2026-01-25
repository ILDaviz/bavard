import 'schema/schema.dart';

abstract class Migration {
  Future<void> up(Schema schema);
  Future<void> down(Schema schema);
}
