import 'dart:io';
import 'commands/base_command.dart';
import 'commands/make_model_command.dart';
import 'commands/make_pivot_command.dart';

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
      print('Error: Unknown command "$commandName".');
      printUsage();
      exit(1);
    }

    command.run(args.sublist(1));
  }

  void printUsage() {
    print('''
Bavard CLI Tool

Usage:
  dart run bavard <command> [arguments]

Available Commands:''');

    _commands.forEach((name, command) {
      print('  ${name.padRight(15)} ${command.description}');
    });
    
    print('');
    print('Run "dart run bavard <command> --help" for more information on a command.');
  }
}
