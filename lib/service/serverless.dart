import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf.dart';

import 'helpers.dart';

class ServerlessService extends LitGameRestService {
  Uri fakeUri(String uri) => Uri.parse('http://rest-server:8042$uri');

  Future<Response> request(String method, String uri, {String? body}) async {
    await init;
    if (method.toUpperCase() != 'GET' && body != null) {
      return await handler(
          Request(method, fakeUri(uri), body: body, headers: jsonHttpHeader));
    }
    return await handler(Request(method, fakeUri(uri)));
  }
}
