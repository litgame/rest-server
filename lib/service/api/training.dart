import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:litgame_server/service/helpers.dart';
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

    var collectionName = validator.validatedJson['collectionName'];
    if (collectionName == null) {
      collectionName = 'default';
    }
    final flow =
        validator.game.startTraining(collectionName: collectionName.toString());
    if (flow == null) {
      return ErrorResponse('Error during training start');
    }

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

    await validator.game.gameFlow?.init;

    error = validator.checkIfTriggeredAtMyTurn(flow);
    if (error != null) {
      return error;
    }

    flow.nextTurn();
    final card = flow.getCard();
    return SuccessResponse(
        // ignore: invalid_use_of_protected_member
        {
          'gameId': validator.game.id,
          'playerId': flow.currentUser.id,
          'card': card.toJson()
        });
  }
}
