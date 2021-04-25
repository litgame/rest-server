import 'dart:convert';

import 'package:litgame_bpmn/models/cards/card.dart';
import 'package:litgame_bpmn/service/helpers.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() async {
  parseInit();
  test("Game start", () async {
    final game = await startTrainingWithThreePlayers();

    var response = await testRequest('PUT', '/api/game/game/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-3',
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/game/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    final objResponse = jsonDecode(await response.readAsString());

    expect(objResponse['gameId'].toString(), game.id);
    expect(objResponse['state'].toString(), 'game');
    expect(objResponse['flowState'].toString(), 'storyTell');
    final cards = objResponse['initialCards'] as List;
    expect(cards.length, 3);
    game.stop();
  });

  test("Game next turn test", () async {
    final game = await startTrainingWithThreePlayers();

    var response = await testRequest('PUT', '/api/game/game/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    response = await testRequest('PUT', '/api/game/game/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-2',
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/game/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    expect(game.gameFlow?.currentUser.id, 'testUser-2');

    game.stop();
  });

  test("Game select next card", () async {
    final game = await startTrainingWithThreePlayers();

    var response = await testRequest('PUT', '/api/game/game/start',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    response = await testRequest('PUT', '/api/game/game/next',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));

    response = await testRequest('PUT', '/api/game/game/selectCard',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'selectCardType': 'generic'
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/game/selectCard',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-2',
          'selectCardType': 'generic'
        }.toJson());

    expect(response.statusCode, equals(200));

    final objResponse = jsonDecode(await response.readAsString());
    expect(objResponse['playerId'].toString(), 'testUser-2');
    expect(objResponse['flowState'].toString(), 'storyTell');

    final card = Card.clone();
    card.fromJson(objResponse['card']);
    expect(card.cardType, CardType.generic);

    game.stop();
  });
}
