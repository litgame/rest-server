import 'dart:io';

import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final service = LitGameRestService();
  await service.init;

  final env = Platform.environment;
  final host = env['GAME_REST_HOST'];
  final port = env['GAME_REST_PORT'];
  if (host == null || port == null) {
    throw 'No host or port specified';
  }

  final server = await shelf_io.serve(service.handler, host, int.parse(port));
  print('Server running on localhost:${server.port}');
}
