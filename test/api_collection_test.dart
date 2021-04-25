import 'package:test/test.dart';

import 'helpers.dart';

void main() async {
  test("List of collections", () async {
    var response = await testRequest('GET', '/api/collection/list');
    expect(response.statusCode, equals(200));
  });
}
