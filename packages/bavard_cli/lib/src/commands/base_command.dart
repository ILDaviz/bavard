abstract class BaseCommand {
  String get name;
  String get description;

  Future<int> run(List<String> args);
  void printUsage();
}
