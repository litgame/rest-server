import 'package:args/args.dart';
import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> arguments) async {
  final service = LitGameRestService();
  await service.init;

  var host = '';
  var port = 0;

  final parser = ArgParser()
    ..addOption('host', abbr: 'h', defaultsTo: 'localhost')
    ..addOption('port', abbr: 'p', defaultsTo: 8080.toString());

  final results = parser.parse(arguments);

  host = results['host'];
  port = int.parse(results['port']);

  final server = await shelf_io.serve(service.handler, host, port);
  print('Server running on $host:${server.port}');
}
