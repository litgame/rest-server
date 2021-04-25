import 'package:litgame_server/models/game/flow_interface.dart';
import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:shelf/shelf.dart';

import '../../helpers.dart';

enum FlowValidatorType { game, training }

class FlowValidator extends TriggeredByValidator {
  FlowValidator(
      Request request, this.type, Map<String, BodyItemValidator?> rules)
      : super(request, rules);

  final FlowValidatorType type;

  @override
  Future<Response?> validate() async {
    var error = await super.validate();
    if (error != null) {
      return error;
    }

    if (game.state != GameState.game && game.state != GameState.training) {
      return ErrorResponse(
          'The game must to be in "game" or "training" state. Current state is ${game.state.toString()}');
    }

    var flow;
    switch (type) {
      case FlowValidatorType.game:
        flow = game.gameFlow;
        if (flow == null) {
          return ErrorResponse('Fatal error: game flow object lost');
        }
        break;
      case FlowValidatorType.training:
        flow = game.trainingFlow;
        if (flow == null) {
          return ErrorResponse('Fatal error: training flow object lost');
        }
        break;
    }

    error = checkIfTriggeredAtMyTurn(flow);
    if (error != null) {
      return error;
    }
  }

  ErrorResponse? checkIfTriggeredAtMyTurn(FlowInterface flow) {
    if (triggeredBy != flow.currentUser.id) {
      return ErrorResponse('It\'s not user\'s $triggeredBy turn now. '
          'Player ${flow.currentUser.id} should trigger next turn');
    }
    return null;
  }
}
