import 'package:litgame_bpmn/models/game/game.dart';
import 'package:litgame_bpmn/models/game/user.dart';
import 'package:litgame_bpmn/service/api/actions/kick_action.dart';
import 'package:litgame_bpmn/service/api/actions/sort_action.dart';
import 'package:litgame_bpmn/service/api/training.dart';
import 'package:litgame_bpmn/service/service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../helpers.dart';
import 'game.dart';
import 'validators/target_user.dart';
import 'validators/triggered_by.dart';

class ApiMainService implements RestService {
  @override
  Router get router {
    final router = Router();

    router.put('/startGame', _startGame);
    router.put('/endGame', _endGame);
    router.put('/join', _join);
    router.put('/kick', _kick);
    router.put('/finishJoin', _finishJoin);
    router.put('/setMaster', _setMaster);
    router.put('/sortPlayer', _sortPlayer);

    router.mount('/training/', ApiTrainingService().router);
    router.mount('/game/', ApiGameService().router);

    return router;
  }

  Future<Response> _startGame(Request request) async {
    final validator = JsonBodyValidator(request, {
      'gameId': (value, _) => value.toString().isNotEmpty
          ? null
          : "can't start game without an id!",
      'adminId': (value, _) =>
          value.toString().isNotEmpty ? null : "can't start game without admin!"
    });
    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    final newGame = LitGame.startNew(validator.validatedJson['gameId']);
    newGame
        .addPlayer(LitUser(validator.validatedJson['adminId'], isAdmin: true));
    return SuccessResponse({'gameId': newGame.id, 'status': 'started'});
  }

  Future<Response> _endGame(Request request) async {
    final validator = TriggeredByValidator(request, {});
    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    final game = validator.game;
    if (game.admin.id != validator.triggeredBy) {
      return ErrorResponse('Only admin can finish the game!');
    }

    try {
      game.stop();
    } catch (error) {
      return ErrorResponse(error.toString());
    }

    return SuccessResponse({'gameId': game.id, 'status': 'finished'});
  }

  Future<Response> _join(Request request) async {
    final validator = TriggeredByValidator(request, {});

    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    final game = validator.game;
    if (game.state == GameState.join) {
      if (game.addPlayer(LitUser(validator.triggeredBy))) {
        return SuccessResponse(
            {'userId': validator.triggeredBy, 'joined': true});
      } else {
        return ErrorResponse(
            "Can't add user ${validator.triggeredBy}: probably already playing");
      }
    } else {
      return ErrorResponse("Can't join player in game state ${game.state}");
    }
  }

  Future<Response> _kick(Request request) async {
    final validator = TargetUserValidator(request, {});

    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    final game = validator.game;
    final targetUserId = validator.targetUserId.toString();
    final action = KickAction(
        game, validator.triggeredBy, targetUserId, validator.validatedJson);
    return action.run();
  }

  Future<Response> _finishJoin(Request request) async {
    final validator = TriggeredByValidator(request, {});

    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    if (validator.game.admin.id != validator.triggeredBy) {
      return ErrorResponse('Only admin can end join phase');
    }

    if (validator.game.startSorting()) {
      return SuccessResponse({'gameId': validator.game.id, 'state': 'sorting'});
    } else {
      return ErrorResponse(
          'Can\'t start sorting from state ${validator.game.state.toString()}'
          ' with ${validator.game.players.length} players');
    }
  }

  Future<Response> _setMaster(Request request) async {
    final validator = TargetUserValidator(request, {});

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    error = validator.checkIfMasterOrAdmin(
        'Only admin or another master can set game master');
    if (error != null) {
      return error;
    }

    final targetUserId = validator.targetUserId.toString();
    final player = validator.game.players[targetUserId];
    if (player == null) {
      return ErrorResponse('Player $targetUserId not found in game');
    }

    validator.game.players.forEach((id, player) {
      player.isGameMaster = false;
    });
    player.isGameMaster = true;

    return SuccessResponse(
        {'gameId': validator.game.id, 'newMaster': player.id});
  }

  Future<Response> _sortPlayer(Request request) async {
    final validator = TargetUserValidator(request, {
      'position': (value, _) {
        if (value.toString().isEmpty) {
          return "Can't sort player without 'position' field";
        }
        try {
          final position = int.parse(value.toString());
        } catch (error) {
          return 'Cant parse position value: ' + error.toString();
        }
      }
    });

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    final action = SortAction(validator);
    return action.run();
  }
}
