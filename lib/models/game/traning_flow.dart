import 'dart:math';

import '../cards/card.dart';
import 'flow_interface.dart';
import 'game_flow.dart';
import 'user.dart';

class TrainingFlow implements FlowInterface {
  static final Map<String, TrainingFlow> _runningTrainings = {};

  TrainingFlow(GameFlow gameFlow) {
    _gameFlow = gameFlow;
    gameFlow.init.then((value) {
      _user = gameFlow.game.playersSorted.first;
      _prepareCards();
    });
  }

  GameFlow get gameFlow {
    if (_gameFlow == null) {
      throw 'No gameFlow in training flow!';
    }
    return _gameFlow!;
  }

  GameFlow? _gameFlow;
  late LinkedUser _user;
  int turnNumber = 1;
  late List<Card> cards;

  @override
  LitUser get currentUser => _user.user;

  factory TrainingFlow.init(GameFlow flow) {
    var trainingFlow = _runningTrainings[flow.game.id];
    trainingFlow ??= TrainingFlow(flow);
    _runningTrainings[flow.game.id] = trainingFlow;
    return trainingFlow;
  }

  void _prepareCards() {
    cards = [];
    gameFlow.cards.forEach((key, value) {
      cards.addAll(List.from(value));
    });
    cards.shuffle(Random(cards.length));
  }

  void stop() {
    if (_runningTrainings[gameFlow.game.id] != null) {
      _runningTrainings.remove(gameFlow.game.id);
    }
    _gameFlow = null;
  }

  @override
  void nextTurn() {
    var next = _user.next;
    next ??= gameFlow.game.playersSorted.first;
    _user = next;
    turnNumber++;
  }

  Card getCard() {
    if (cards.isEmpty) {
      _prepareCards();
    }
    return cards.removeLast();
  }
}
