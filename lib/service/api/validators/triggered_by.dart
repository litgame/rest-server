import 'package:litgame_server/models/game/game.dart';
import 'package:shelf/shelf.dart';

import '../../helpers.dart';

class TriggeredByValidator extends JsonBodyValidator {
  TriggeredByValidator(Request request, Map<String, BodyItemValidator?> rules)
      : super(
            request,
            {
              'triggeredBy': (value, _) => value.toString().isNotEmpty
                  ? null
                  : "can't finish game by unknown user!",
              'gameId': (value, _) {
                final gameId = value.toString();
                if (gameId.isEmpty) {
                  return "can't end game without an id!";
                }
                final game = LitGame.find(gameId);
                if (game == null) {
                  return "game with id $gameId not found";
                }
              }
            }..addEntries(rules.entries));

  String get gameId => validated['gameId'];

  LitGame get game => LitGame.find(gameId) as LitGame;

  String get triggeredBy => validated['triggeredBy'];

  ErrorAccessResponse? checkIfMasterOrAdmin(String errorDescription) {
    if (game.admin.id != triggeredBy) {
      final errResponse = ErrorAccessResponse(errorDescription);
      try {
        if (game.master.id != triggeredBy) {
          return errResponse;
        }
      } catch (_) {
        return errResponse;
      }
    }
  }
}
