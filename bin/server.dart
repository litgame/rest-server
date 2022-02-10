import 'dart:io';

import 'package:args/args.dart';
import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> arguments) async {
  final service = LitGameRestService();
  await service.init;

  var host = '';
  var port = 0;

  if (arguments.isEmpty) {
    final env = Platform.environment;
    host = env['GAME_REST_HOST'] ?? 'localhost';
    if (env['GAME_REST_PORT'] == null) {
      port = 8042;
    } else {
      port = int.tryParse(env['GAME_REST_PORT']!) ?? 8042;
    }
  } else {
    final parser = ArgParser()
      ..addOption('host', abbr: 'h', defaultsTo: 'localhost')
      ..addOption('port', abbr: 'p', defaultsTo: 8042.toString());

    final results = parser.parse(arguments);
    host = results['host'];
    port = int.parse(results['port']);
  }

  final server = await shelf_io.serve(service.handler, host, port);
  print('Server running on $host:${server.port}');
}
