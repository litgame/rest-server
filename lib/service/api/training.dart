import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:litgame_server/service/helpers.dart';
import 'package:litgame_server/service/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';

import '../service.dart';
import 'validators/flow.dart';

class ApiTrainingService implements RestService {
  @override
  Router get router {
    final router = Router();

    router.put('/start', _startTraining);
    router.put('/next', _nextTurn);
    router.put('/skip', _skip);

    return router;
  }

  Future<Response> _startTraining(Request request) async {
    final validator = TriggeredByValidator(request, {});

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    error = validator
        .checkIfMasterOrAdmin('Only admin or master can start training');
    if (error != null) {
      return error;
    }

    if (validator.game.state != GameState.sorting) {
      return ErrorStateResponse(
          'Cant start training at state ${validator.game.state.toString()}');
    }

    if (validator.game.players.length != validator.game.playersSorted.length) {
      return ErrorResponse(
          'Only ${validator.game.playersSorted.length} of total ${validator.game.players.length} were sorted ');
    }

    var collectionName = validator.validated['collectionName'];
    if (collectionName == null) {
      collectionName = 'default';
    }

    var collectionId = validator.validated['collectionId'];

    final flow = validator.game.startTraining(
        collectionName: collectionName.toString(), collectionId: collectionId);
    if (flow == null) {
      return ErrorResponse('Error during training start');
    }

    await flow.gameFlow.init;
    return SuccessResponse({'gameId': validator.game.id, 'state': 'training'});
  }

  Future<Response> _nextTurn(Request request) async {
    final validator = FlowValidator(request, FlowValidatorType.training, {});

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    if (validator.game.state != GameState.training) {
      return ErrorStateResponse(
          'The game must to be in training state. Current state is ${validator.game.state.toString()}');
    }

    final flow = validator.game.trainingFlow;
    if (flow == null) {
      return ErrorResponse('Fatal error: game flow object lost');
    }

    if (flow.turnNumber > 1) {
      flow.nextTurn();
    } else {
      flow.turnNumber++;
    }
    final card = flow.getCard();
    return SuccessResponse({
      'gameId': validator.game.id,
      'playerId': flow.currentUser.id,
      'card': card.toJson()
    });
  }

  Future<Response> _skip(Request request) async {
    final validator = FlowValidator(request, FlowValidatorType.training, {});

    var error = await validator.validate(skipTurnCheck: true);
    if (error != null) {
      return error;
    }

    if (validator.game.state != GameState.training) {
      return ErrorStateResponse(
          'The game must to be in training state. Current state is ${validator.game.state.toString()}');
    }

    final flow = validator.game.trainingFlow;
    if (flow == null) {
      return ErrorResponse('Fatal error: game flow object lost');
    }

    error = validator
        .checkIfMasterOrAdmin('Only admin or master can skip a player\'s turn');
    if (error != null) {
      return error;
    }

    if (flow.turnNumber > 1) {
      flow.nextTurn();
    } else {
      flow.turnNumber++;
    }
    final card = flow.getCard();
    return SuccessResponse({
      'gameId': validator.game.id,
      'playerId': flow.currentUser.id,
      'card': card.toJson()
    });
  }

  @override
  LoggerInterface get logger => ConsoleLogger();
}
