import 'package:litgame_server/models/cards/card.dart';
import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:litgame_server/service/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';

import '../service.dart';
import 'validators/flow.dart';

class ApiGameService implements RestService {
  @override
  Router get router {
    final router = Router();

    router.put('/start', _startGame);
    router.put('/selectCard', _selectCard);
    router.put('/next', _nextTurn);

    return router;
  }

  Future<Response> _startGame(Request request) async {
    final validator = TriggeredByValidator(request, {});

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    error =
        validator.checkIfMasterOrAdmin('Only admin or master can start game');
    if (error != null) {
      return error;
    }

    if (validator.game.state != GameState.training) {
      return ErrorResponse(
          'Cant start game at state ${validator.game.state.toString()}');
    }

    final flow = validator.game.startGame();
    if (flow == null) {
      return ErrorResponse('Error during game start');
    }

    final genericCard = flow.getCard(CardType.generic);
    final placeCard = flow.getCard(CardType.place);
    final personCard = flow.getCard(CardType.person);

    return SuccessResponse({
      'gameId': validator.game.id,
      'state': 'game',
      'flowState': 'storyTell',
      'initialCards': [genericCard, placeCard, personCard]
    });
  }

  Future<Response> _selectCard(Request request) async {
    final validator = FlowValidator(request, FlowValidatorType.game, {
      'selectCardType': (value, _) {
        if (!['place', 'generic', 'person'].contains(value.toString())) {
          return 'Invalid card type: $value. Should be either "place", "generic" or "person".';
        }
      }
    });

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    final flow = validator.game.gameFlow;
    if (flow == null) throw 'Fatal error: null flow';

    final cardType = validator.validatedJson['selectCardType'].toString();
    final card = flow.getCard(CardType.generic.getTypeByName(cardType));

    return SuccessResponse({
      'gameId': validator.game.id,
      'playerId': validator.triggeredBy,
      // ignore: invalid_use_of_protected_member
      'card': card.toJson(),
      'flowState': 'storyTell'
    });
  }

  Future<Response> _nextTurn(Request request) async {
    final validator = FlowValidator(request, FlowValidatorType.game, {});

    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    final flow = validator.game.gameFlow;
    if (flow == null) throw 'Fatal error: null flow';

    flow.nextTurn();
    return SuccessResponse({
      'gameId': validator.game.id,
      'playerId': flow.currentUser.id,
      'flowState': 'selectCard'
    });
  }
}
