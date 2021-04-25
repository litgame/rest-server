import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final service = LitGameRestService();
  await service.init;
  final server = await shelf_io.serve(service.handler, 'localhost', 8080);
  print('Server running on localhost:${server.port}');
}
