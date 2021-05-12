import 'package:litgame_server/service/helpers.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() async {
  test("Training start without collection", () async {
    final game = await startTrainingWithThreePlayers(false);

    var response = await testRequest('PUT', '/api/game/training/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    final expected = {'gameId': game.id, 'state': 'training'};
    expect(await response.readAsString(), expected.toJson());
    game.stop();
  });

  test("Training start with specified collection", () async {
    final game = await startTrainingWithThreePlayers(false);

    var response = await testRequest('PUT', '/api/game/training/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'collectionName': 'default',
        }.toJson());

    expect(response.statusCode, equals(200));

    final expected = {'gameId': game.id, 'state': 'training'};
    final strResponse = await response.readAsString();
    expect(strResponse, expected.toJson(), reason: strResponse);
    game.stop();
  });

  test("Training next turn test", () async {
    final game = await startTrainingWithThreePlayers();

    var response = await testRequest('PUT', '/api/game/training/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-2',
        }.toJson());

    expect(response.statusCode, equals(500),
        reason: await response.readAsString());

    response = await testRequest('PUT', '/api/game/training/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200),
        reason: await response.readAsString());
    expect(game.trainingFlow?.currentUser.id, 'testUser-1');

    response = await testRequest('PUT', '/api/game/training/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200),
        reason: await response.readAsString());
    expect(game.trainingFlow?.currentUser.id, 'testUser-2');

    game.stop();
  });
}
