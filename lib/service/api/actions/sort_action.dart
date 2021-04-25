import 'package:litgame_bpmn/models/game/game.dart';
import 'package:litgame_bpmn/models/game/user.dart';
import 'package:litgame_bpmn/service/api/actions/core.dart';
import 'package:litgame_bpmn/service/api/validators/target_user.dart';
import 'package:shelf/src/response.dart';

import '../../helpers.dart';

class SortAction implements Action {
  SortAction(this.validator);

  TargetUserValidator validator;

  @override
  Future<Response> run() async {
    var error = await validator.validate();
    if (error != null) {
      return error;
    }

    error =
        validator.checkIfMasterOrAdmin('Only admin or master can sort players');
    if (error != null) {
      return error;
    }

    if (validator.game.state != GameState.sorting) {
      return ErrorResponse(
          "Can't sort players at ${validator.game.state.toString()} state");
    }

    final playerToSort = validator.game.players[validator.targetUserId];
    if (playerToSort == null) {
      return ErrorResponse(
          'Player ${validator.targetUserId} not found in game');
    }
    final position = int.parse(validator.validatedJson['position'].toString());
    final playersSorted = validator.game.playersSorted;
    if (playersSorted.length == 0) {
      playersSorted.add(LinkedUser(playerToSort));
      return SuccessResponse({
        'gameId': validator.game.id,
        'playerPosition': 0,
      });
    } else {
      try {
        final existing = playersSorted
            .firstWhere((element) => element.user.id == validator.targetUserId);
        existing.unlink();
      } catch (_) {}

      if (position < 0) {
        playersSorted.addFirst(LinkedUser(playerToSort));
        return SuccessResponse({
          'gameId': validator.game.id,
          'playerPosition': 0,
        });
      } else if (position >= playersSorted.length) {
        playersSorted.add(LinkedUser(playerToSort));
        return SuccessResponse({
          'gameId': validator.game.id,
          'playerPosition': playersSorted.length,
        });
      } else {
        var counter = 0;
        for (var sorted in playersSorted) {
          if (counter == position) {
            sorted.insertBefore(LinkedUser(playerToSort));
            return SuccessResponse({
              'gameId': validator.game.id,
              'playerPosition': position,
            });
          }
        }
      }
    }
    return ErrorResponse('Unknown error during sorting');
  }
}
