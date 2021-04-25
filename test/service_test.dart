import 'package:litgame_server/service/helpers.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test("/version and / test", () async {
    var response = await testRequest('GET', '/version');
    expect(response.statusCode, equals(200));
    final expected = {'version': '1.0'}.toJson();
    var actual = await response.readAsString();
    expect(actual, expected);

    response = await testRequest('GET', '/');
    expect(response.statusCode, equals(200));
    actual = await response.readAsString();
    expect(actual, expected);
  });
}
