import 'dart:math';

import '../cards/card.dart';
import '../cards/card_collection.dart';
import 'flow_interface.dart';
import 'game.dart';
import 'user.dart';

enum GameFlowState { masterInit, storyTell, selectCard, paused }

class GameFlow implements FlowInterface {
  static final Map<String, GameFlow> _runningGames = {};
  static final Map<String, CardCollection> _loadedCollections = {};

  final LitGame game;
  final String collectionName;
  late final Future init;
  Map<String, List<Card>> cards = {};

  CardCollection? get _collection => _loadedCollections[collectionName];

  String get collectionId => _loadedCollections[collectionName]?.objectId ?? '';

  late LinkedUser _user;
  int turnNumber = 0;
  var _state = GameFlowState.masterInit;

  GameFlowState get state => _state;

  factory GameFlow.init(LitGame game,
      {String collectionName = '',
      String? collectionId,
      Map<String, List<Card>>? cards}) {
    var flow = _runningGames[game.id];
    if (cards == null) {
      if (collectionId != null) {
        flow ??= GameFlow.serverCollection(game, collectionId: collectionId);
      } else {
        flow ??=
            GameFlow.serverCollection(game, collectionName: collectionName);
      }
    } else {
      flow ??= GameFlow.staticCollection(game, cards, collectionName);
    }
    _runningGames[game.id] = flow;
    return flow;
  }

  GameFlow.serverCollection(this.game,
      {this.collectionName = '', String? collectionId}) {
    _user = game.playersSorted.first;

    if (collectionId != null) {
      init = CardCollection.fromServer(id: collectionId);
    } else {
      init = CardCollection.fromServer(name: collectionName);
    }
    init.then((loadedCollection) {
      _loadedCollections[collectionName] = loadedCollection;
      _collection?.cards.forEach((key, value) {
        cards[key] = List.from(value);
      });
    });
  }

  GameFlow.staticCollection(this.game, Map<String, List<Card>> staticCards,
      [String? colName])
      : this.collectionName = colName ?? 'internal-offline' {
    _user = game.playersSorted.first;
    final offlineCollection = CardCollection(collectionName);
    offlineCollection.cards.addAll(Map.from(staticCards));
    _loadedCollections[collectionName] = offlineCollection;
    _collection?.cards.forEach((key, value) {
      cards[key] = List.from(value);
    });
    init = Future.value(null);
  }

  static void stopGame(String gameId) {
    if (_runningGames[gameId] != null) {
      _runningGames.remove(gameId);
    }
  }

  @override
  LitUser get currentUser => _user.user;

  @override
  void nextTurn() {
    var next = _user.next;
    next ??= game.playersSorted.first;
    _user = next;
    turnNumber++;
    _state = GameFlowState.selectCard;
  }

  Card getCard(CardType type) {
    var list = cards[type.value()];
    if (list == null) throw 'Collection error';
    if (list.isEmpty) {
      var cc = _collection?.cards[type.value()];
      if (cc != null) {
        cc.shuffle(Random(cc.length));
        cards[type.value()] = List.from(cc);
        return getCard(type);
      }
    }
    _state = GameFlowState.storyTell;
    return list.removeLast();
  }
}
