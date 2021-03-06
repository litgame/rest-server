import 'package:litgame_server/models/cards/card.dart';
import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/models/game/user.dart';
import 'package:litgame_server/service/serverless.dart';
import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf.dart';

Future<Response> testRequest(String method, String uri, {String? body}) async {
  final service = ServerlessService(LitGameRestService());
  return service.request(method, uri, body: body);
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
    LitGame.setOfflineCards(testCollection());
    game.startTraining();
    await game.gameFlow?.init;
  }
  return game;
}
