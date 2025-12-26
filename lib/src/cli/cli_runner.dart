import 'dart:io';
import 'commands/base_command.dart';
import 'commands/make_model_command.dart';
import 'commands/make_pivot_command.dart';
import 'utils.dart';

class CliRunner {
  final Map<String, BaseCommand> _commands = {};

  CliRunner() {
    _register(MakeModelCommand());
    _register(MakePivotCommand());
  }

  void _register(BaseCommand command) {
    _commands[command.name] = command;
  }

  void run(List<String> args) {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      if (args.isEmpty || (args.length == 1 && (args[0] == '--help' || args[0] == '-h'))) {
        printUsage();
        return;
      }
    }

    final commandName = args[0];
    final command = _commands[commandName];

    if (command == null) {
      printError('Unknown command "$commandName".');
      printUsage();
      exit(1);
    }

    command.run(args.sublist(1));
  }

  void printUsage() {
    print('${colorized('Bavard CLI Tool', bold + cyan)}\n');
    print('${colorized('Usage:', bold)}');
    print('  dart run bavard <command> [arguments]\n');
    print('${colorized('Available Commands:', bold)}');

    _commands.forEach((name, command) {
      print('  ${colorized(name.padRight(15), green)} ${command.description}');
    });
    
    print('');
    print('Run "dart run bavard <command> --help" for more information on a command.');
  }
}
