import 'dart:collection';

import 'package:litgame_server/models/cards/card.dart';
import 'package:litgame_server/models/game/game_flow.dart';
import 'package:litgame_server/models/game/traning_flow.dart';

import 'user.dart';

enum GameState { stop, join, sorting, training, game, paused }

class LitGame {
  LitGame._(this.id) : _playersSorted = LinkedList<LinkedUser>();

  static final Map<String, LitGame> _activeGames = {};
  final String id;
  final Map<String, LitUser> _players = {};
  final LinkedList<LinkedUser> _playersSorted;
  GameState _state = GameState.stop;

  GameState get state => _state;

  Map<String, LitUser> get players => _players;

  LinkedList<LinkedUser> get playersSorted => _playersSorted;

  TrainingFlow? _trainingFlow;
  TrainingFlow? get trainingFlow => _trainingFlow;
  GameFlow? _gameFlow;
  GameFlow? get gameFlow => _gameFlow;

  bool get isEmpty => id == -1;

  static Map<String, List<Card>>? _offlineCards;

  static setOfflineCards(Map<String, List<Card>>? value) {
    if (value == null)
      _offlineCards = value;
    else {
      _offlineCards = Map.of(value);
    }
  }

  LitUser get master {
    for (var u in _players.values) {
      if (u.isGameMaster) return u;
    }
    throw 'No master added';
  }

  LitUser get admin {
    for (var u in _players.values) {
      if (u.isAdmin) return u;
    }
    return master;
  }

  factory LitGame.startNew(String id) {
    if (_activeGames[id] != null) {
      throw 'Game already exists!';
    }
    final game = LitGame._(id);
    _activeGames[id] = game;
    game._state = GameState.join;
    return game;
  }

  static LitGame? find(String gameId) {
    return _activeGames[gameId];
  }

  static Map<String, LitGame> allGames() => _activeGames;

  static void stopGame(String gameId) {
    if (_activeGames[gameId] == null) {
      throw 'Game $gameId does not exists. Cant stop it!';
    }
    _activeGames.remove(gameId);
  }

  void stop() {
    if (_activeGames[id] == null) {
      throw 'Game $id does not exists. Cant stop it!';
    }
    _activeGames.remove(id);
    _trainingFlow?.stop();
    _trainingFlow = null;
    _gameFlow?.stop();
    _gameFlow = null;
    _state = GameState.stop;
  }

  bool startSorting() {
    if (_state != GameState.join) return false;
    if (players.length < 1) return false;
    _state = GameState.sorting;
    return true;
  }

  TrainingFlow? startTraining(
      {String collectionName = '',
      String? collectionId,
      Map<String, List<Card>>? cards}) {
    try {
      master;
      if (_state != GameState.sorting) {
        return null;
      }
      cards ??= _offlineCards;
      if (cards == null) {
        if (collectionId != null) {
          _gameFlow = GameFlow.init(this, collectionId: collectionId);
        } else {
          _gameFlow = GameFlow.init(this, collectionName: collectionName);
        }
      } else {
        _gameFlow =
            GameFlow.init(this, cards: cards, collectionName: collectionName);
      }
      _trainingFlow = TrainingFlow.init(_gameFlow as GameFlow);
      _state = GameState.training;
      return _trainingFlow;
    } catch (error) {
      return null;
    }
  }

  GameFlow? startGame() {
    try {
      master;
      if (_gameFlow != null) {
        _state = GameState.game;
      }
      return _gameFlow;
    } catch (error) {
      return null;
    }
  }

  static LitUser? findPlayerInExistingGames(String userId) {
    for (var game in _activeGames.entries) {
      final player = game.value.players[userId];
      if (player != null) {
        return player;
      }
    }
  }

  static LitGame? findGameOfPlayer(String userId) {
    for (var game in _activeGames.entries) {
      final player = game.value.players[userId];
      if (player != null) {
        return game.value;
      }
    }
  }

  @override
  bool operator ==(other) {
    if (other is LitGame) {
      return id == other.id;
    }
    return false;
  }

  bool isPlayerPlaying(LitUser user) =>
      findPlayerInExistingGames(user.id) != null;

  bool addPlayer(LitUser user) {
    if (isPlayerPlaying(user)) {
      return false;
    }
    _players[user.id] = user;
    return true;
  }

  void removePlayer(LitUser user) {
    _players.remove(user.id);
    if (playersSorted.isNotEmpty) {
      try {
        final player =
            playersSorted.firstWhere((element) => element.user.id == user.id);
        playersSorted.remove(player);
      } catch (e) {
        print(e);
        print(user);
        print(user.id);
      }
    }
  }

  Map toJson() {
    var gameMaster;
    var gameAdmin;
    try {
      gameMaster = master;
    } catch (e) {}
    try {
      gameAdmin = admin;
    } catch (e) {}

    return {
      'id': id,
      'state': state.toString(),
      'players': players,
      'playersOrder': playersSorted.toList(growable: false),
      'admin': gameAdmin,
      'master': gameMaster,
    };
  }
}
