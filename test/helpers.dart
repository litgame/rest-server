import 'dart:io';

import 'package:litgame_bpmn/models/cards/card.dart';
import 'package:litgame_bpmn/models/cards/card_collection.dart';
import 'package:litgame_bpmn/models/game/game.dart';
import 'package:litgame_bpmn/models/game/user.dart';
import 'package:litgame_bpmn/service/helpers.dart';
import 'package:litgame_bpmn/service/service.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shelf/shelf.dart';

Uri testUri(String uri) => Uri.parse('http://localhost:8080$uri');

Future<Response> testRequest(String method, String uri, {String? body}) async {
  final service = LitGameRestService();
  final handler = service.handler;
  if (method.toUpperCase() != 'GET' && body != null) {
    return await handler(
        Request(method, testUri(uri), body: body, headers: jsonHttpHeader));
  }
  return await handler(Request(method, testUri(uri)));
}

Future<void> parseInit() async {
  final envVars = Platform.environment;
  var useDefault = false;
  final _dataAppUrl = envVars['BOT_PARSESERVER_URL'];
  if (_dataAppUrl == null) useDefault = true;

  final _dataAppKey = envVars['BOT_PARSESERVER_APP_KEY'];
  if (_dataAppKey == null) useDefault = true;

  final _parseMasterKey = envVars['BOT_PARSESERVER_MASTER_KEY'];
  if (_parseMasterKey == null) useDefault = true;

  final _parseRestKey = envVars['BOT_PARSESERVER_REST_KEY'];
  if (_parseRestKey == null) useDefault = true;

  if (useDefault) {
    await Parse().initialize(
      'appId',
      'https://test.parse.com',
      debug: true,
      // to prevent automatic detection
      fileDirectory: 'someDirectory',
      // to prevent automatic detection
      appName: 'appName',
      // to prevent automatic detection
      appPackageName: 'somePackageName',
      // to prevent automatic detection
      appVersion: 'someAppVersion',
    );
  } else {
    await Parse().initialize(
      _dataAppKey as String,
      _dataAppUrl as String,
      masterKey: _parseMasterKey,
      clientKey: _parseRestKey,
      debug: true,
      registeredSubClassMap: <String, ParseObjectConstructor>{
        'LitUsers': () => LitUser.clone(),
        'Card': () => Card.clone(),
        'CardCollection': () => CardCollection.clone(),
      },
      // to prevent automatic detection
      fileDirectory: 'someDirectory',
      // to prevent automatic detection
      appName: 'appName',
      // to prevent automatic detection
      appPackageName: 'somePackageName',
      // to prevent automatic detection
      appVersion: 'someAppVersion',
    );
  }
}

Card testCard(String name, CardType type) =>
    Card(name, 'http://localhost/test.jpg', type, 'test');

Map<String, List<Card>> testCollection() {
  final collection = <String, List<Card>>{};
  collection['place'] = [
    testCard('place-1', CardType.place),
    testCard('place-2', CardType.place),
    testCard('place-3', CardType.place),
  ];
  collection['generic'] = [
    testCard('generic-1', CardType.generic),
    testCard('generic-2', CardType.generic),
    testCard('generic-3', CardType.generic),
  ];
  collection['person'] = [
    testCard('person-1', CardType.person),
    testCard('person-2', CardType.person),
    testCard('person-3', CardType.person),
  ];
  return collection;
}

Future<LitGame> startTrainingWithThreePlayers([bool start = true]) async {
  final game = LitGame.startNew('test-123');
  final user1 = LitUser('testUser-1', isAdmin: true);
  final user2 = LitUser('testUser-2', isGameMaster: true);
  final user3 = LitUser('testUser-3');
  game.addPlayer(user1);
  game.addPlayer(user2);
  game.addPlayer(user3);
  game.startSorting();
  game.playersSorted.add(LinkedUser(user1));
  game.playersSorted.add(LinkedUser(user2));
  game.playersSorted.add(LinkedUser(user3));
  if (start) {
    game.startTraining(cards: testCollection());
    await game.gameFlow?.init;
  }
  return game;
}
