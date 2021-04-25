import 'package:litgame_bpmn/models/game/game.dart';
import 'package:litgame_bpmn/models/game/user.dart';
import 'package:litgame_bpmn/service/helpers.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() async {
  test("/startGame test", () async {
    var response = await testRequest('PUT', '/api/game/startGame',
        body: {'gameId': 'test-123', 'adminId': 'testUser-123'}.toJson());
    expect(response.statusCode, equals(200));
    final expected = {'gameId': 'test-123', 'status': 'started'}.toJson();
    var actual = await response.readAsString();
    expect(actual, expected);
    LitGame.stopGame('test-123');
  });

  test("/endGame test", () async {
    final game = LitGame.startNew('test-123');
    game.addPlayer(LitUser('testUser-123', isAdmin: true));

    var response = await testRequest('PUT', '/api/game/endGame',
        body: {'gameId': 'invalid', 'triggeredBy': 'invalid'}.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/endGame',
        body: {'gameId': 'test-123', 'triggeredBy': 'testUser-123'}.toJson());

    expect(response.statusCode, equals(200));
    final expected = {'gameId': 'test-123', 'status': 'finished'}.toJson();
    var actual = await response.readAsString();
    expect(actual, expected);
  });

  test("/join test", () async {
    final game = LitGame.startNew('test-123');
    game.addPlayer(LitUser('testUser-123', isAdmin: true));

    var response = await testRequest('PUT', '/api/game/join',
        body: {'gameId': 'test-123', 'triggeredBy': 'testUser-123'}.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/join',
        body: {'gameId': 'test-123', 'triggeredBy': 'testUser-new'}.toJson());

    expect(response.statusCode, equals(200));
    final expected = {'userId': 'testUser-new', 'joined': true}.toJson();
    var actual = await response.readAsString();
    expect(actual, expected);

    game.stop();
  });

  test("/kick test while joining to game", () async {
    final game = LitGame.startNew('test-123');
    game.addPlayer(LitUser('testUser-1', isAdmin: true));
    game.addPlayer(LitUser('testUser-2', isGameMaster: true));
    game.addPlayer(LitUser('testUser-3'));

    var response = await testRequest('PUT', '/api/game/kick',
        body: {'gameId': 'test-123', 'triggeredBy': 'testUser-2'}.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/kick',
        body: {'gameId': 'test-123', 'triggeredBy': 'testUser-1'}.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.players.length, 2);

    response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-1'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.state, GameState.stop);
  });

  test("/kick test while game training", () async {
    final game = await startTrainingWithThreePlayers();

    var response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.players.length, 2);
    var actual = await response.readAsString();
    expect(
        actual,
        {
          'userId': 'testUser-3',
          'removed': true,
        }.toJson());

    game.addPlayer(LitUser('testUser-3'));

    response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2'
        }.toJson());

    expect(response.statusCode, equals(500),
        reason: await response.readAsString());

    response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2',
          'newMasterId': 'testUser-22'
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': 'test-123',
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2',
          'newMasterId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(200));
    game.stop();
  });

  test('check if nextTurn worked when kick during game', () async {
    final game = await startTrainingWithThreePlayers();

    game.trainingFlow?..nextTurn()..nextTurn(); //testUser-3 turn;

    // kick testUser-3
    var response = await testRequest('PUT', '/api/game/kick',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.players.length, 2);
    expect(game.trainingFlow?.currentUser.id, 'testUser-1');
    game.stop();
  });

  test('finish join stage of game', () async {
    final game = LitGame.startNew('test-123');
    final user1 = LitUser('testUser-1', isAdmin: true);
    game.addPlayer(user1);

    var response = await testRequest('PUT', '/api/game/finishJoin',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(500));

    final user2 = LitUser('testUser-2', isGameMaster: true);
    game.addPlayer(user2);

    response = await testRequest('PUT', '/api/game/finishJoin',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.state, GameState.sorting);

    game.stop();
  });

  test('set game master', () async {
    final game = LitGame.startNew('test-123');
    final user1 = LitUser('testUser-1', isAdmin: true);
    final user2 = LitUser('testUser-2', isGameMaster: true);
    final user3 = LitUser('testUser-3');
    game.addPlayer(user1);
    game.addPlayer(user2);
    game.addPlayer(user3);

    var response = await testRequest('PUT', '/api/game/setMaster',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-3',
          'targetUserId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/setMaster',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-2',
          'targetUserId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.master.id, 'testUser-3');

    response = await testRequest('PUT', '/api/game/setMaster',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2'
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.master.id, 'testUser-2');

    game.stop();
  });

  test('sort player', () async {
    final game = LitGame.startNew('test-123');
    final user1 = LitUser('testUser-1', isAdmin: true);
    final user2 = LitUser('testUser-2', isGameMaster: true);
    final user3 = LitUser('testUser-3');
    game.addPlayer(user1);
    game.addPlayer(user2);
    game.addPlayer(user3);
    game.startSorting();

    var response = await testRequest('PUT', '/api/game/sortPlayer',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-3',
          'targetUserId': 'testUser-3'
        }.toJson());

    expect(response.statusCode, equals(500));

    response = await testRequest('PUT', '/api/game/sortPlayer',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-2',
          'position': 1
        }.toJson());

    expect(response.statusCode, equals(200));

    response = await testRequest('PUT', '/api/game/sortPlayer',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-3',
          'position': 1
        }.toJson());

    expect(response.statusCode, equals(200));

    response = await testRequest('PUT', '/api/game/sortPlayer',
        body: {
          'gameId': game.id,
          'triggeredBy': 'testUser-1',
          'targetUserId': 'testUser-1',
          'position': 1
        }.toJson());

    expect(response.statusCode, equals(200));
    expect(game.playersSorted.length, 3);
    var sorted = game.playersSorted.first;
    expect(sorted.user.id, 'testUser-2');
    sorted = sorted.next as LinkedUser;
    expect(sorted.user.id, 'testUser-3');
    sorted = sorted.next as LinkedUser;
    expect(sorted.user.id, 'testUser-1');
    game.stop();
  });
}
