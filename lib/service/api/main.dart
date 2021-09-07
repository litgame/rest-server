import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/models/game/user.dart';
import 'package:litgame_server/service/api/actions/kick_action.dart';
import 'package:litgame_server/service/api/actions/sort_action.dart';
import 'package:litgame_server/service/api/training.dart';
import 'package:litgame_server/service/logger.dart';
import 'package:litgame_server/service/service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../error.dart';
import '../helpers.dart';
import 'game.dart';
import 'validators/target_user.dart';
import 'validators/triggered_by.dart';

class ApiMainService implements RestService {
  @override
  Router get router {
    final router = Router();

    router.put('/start', _startGame);
    router.put('/end', _endGame);
    router.put('/join', _join);
    router.put('/kick', _kick);
    router.put('/finishJoin', _finishJoin);
    router.put('/setMaster', _setMaster);
    router.put('/sortPlayer', _sortPlayer);
    router.put('/sortReset', _sortReset);

    router.get('/list', _list);
    router.get('/info', _get);
    router.put('/findGameOfPlayer', _findGameOfPlayer);

    router.mount('/training/', ApiTrainingService().router);
    router.mount('/game/', ApiGameService().router);

    return router;
  }

  Future<Response> _startGame(Request request) async {
    final validator = JsonBodyValidator(request, {
      'gameId': (value, _) => value.toString().isNotEmpty
          ? null
          : "can't start game without an id!",
      'adminId': (value, _) {
        if (value.toString().isEmpty) return "can't start game without admin!";
      }
    });
    final error = await validator.validate();
    if (error != null) {
      return error;
    }
    if (LitGame.findGameOfPlayer(validator.validated['adminId']) != null) {
      return ErrorExistingResponse(
          "can't start new game while playing an existing one");
    }

    final newGame = LitGame.startNew(validator.validated['gameId']);
    newGame.addPlayer(LitUser(validator.validated['adminId'], isAdmin: true));
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
      return ErrorAccessResponse('Only admin can finish the game!');
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
      final existingGame = LitGame.findGameOfPlayer(validator.triggeredBy);
      if (existingGame != null) {
        if (game.id == existingGame.id) {
          return ErrorExistingResponse(
              "Can't add user ${validator.triggeredBy}: already playing this game");
        } else {
          return ErrorAnotherGameResponse(
              "Can't add user ${validator.triggeredBy}: already playing another game",
              existingGame.id);
        }
      }

      if (game.addPlayer(LitUser(validator.triggeredBy))) {
        return SuccessResponse(
            {'userId': validator.triggeredBy, 'joined': true});
      } else {
        return ErrorResponse(
            "Can't add user ${validator.triggeredBy}: probably already playing");
      }
    } else if (game.state == GameState.training ||
        game.state == GameState.game) {
      final targetId = validator.validated['targetUserId'];
      if (targetId == null)
        return ErrorResponse("Can't join player: targetId did not provided");
      int? targetPosition;
      try {
        targetPosition = int.parse(validator.validated['position']);
      } catch (_) {
        return ErrorResponse("Can't join player: position did not provided");
      }

      final error = validator.checkIfMasterOrAdmin(
          'Only master or admin can add new players during game');
      if (error != null) return error;

      final newPlayer = LitUser(targetId);
      game.addPlayer(newPlayer);
      final sortPosition = SortAction.sort(newPlayer, targetPosition, game);
      if (sortPosition < 0) {
        return ErrorResponse('Unknown error during sorting');
      }

      return SuccessResponse({
        'gameId': validator.game.id,
        'userId': targetId,
        'joined': true,
        'playerPosition': sortPosition,
      });
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
        game, validator.triggeredBy, targetUserId, validator.validated, logger);
    return action.run();
  }

  Future<Response> _finishJoin(Request request) async {
    final validator = TriggeredByValidator(request, {});

    final error = await validator.validate();
    if (error != null) {
      return error;
    }

    if (validator.game.admin.id != validator.triggeredBy) {
      return ErrorAccessResponse('Only admin can end join phase');
    }

    if (validator.game.startSorting()) {
      return SuccessResponse({'gameId': validator.game.id, 'state': 'sorting'});
    } else {
      return ErrorStateResponse(
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
      return ErrorNotFoundResponse('Player $targetUserId not found in game');
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
          int.parse(value.toString());
        } catch (error) {
          return 'Cant parse position value: ' + error.toString();
        }
      }
    });

    final action = SortAction(validator, logger);
    return action.run();
  }

  Future<Response> _sortReset(Request request) async {
    final validator = TriggeredByValidator(request, {});
    final action = SortAction(validator, logger);
    return action.run(reset: true);
  }

  Future<Response> _list(Request request) async {
    if (LitGameRestService.debugMode == false) {
      return Response(404,
          body: {
            'error': 'Feature is disabled in production mode',
            'type': ErrorType.notFound.toErrorString()
          }.toJson());
    }
    return SuccessResponse({'games': LitGame.allGames()});
  }

  Future<Response> _get(Request request) async {
    var gameId = request.url.query;
    if (gameId.isEmpty) {
      return ErrorNotFoundResponse('Game id not specified');
    }

    final game = LitGame.find(gameId);
    if (game == null) {
      return ErrorNotFoundResponse('Game not found!');
    }
    return SuccessResponse(game.toJson());
  }

  Future<Response> _findGameOfPlayer(Request request) async {
    final validator = JsonBodyValidator(request, {
      'playerId': (value, _) =>
          value.toString().isNotEmpty ? null : "player is not specified!"
    });

    final error = await validator.validate();
    if (error != null) {
      return error;
    }
    final gameOfPlayer =
        LitGame.findGameOfPlayer(validator.validated['playerId']);
    if (gameOfPlayer == null) {
      return SuccessResponse({'gameId': ''});
    }

    return SuccessResponse({'gameId': gameOfPlayer.id});
  }

  @override
  LoggerInterface get logger => ConsoleLogger();
}
