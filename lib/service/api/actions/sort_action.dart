import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/models/game/user.dart';
import 'package:litgame_server/service/api/actions/core.dart';
import 'package:litgame_server/service/api/validators/target_user.dart';
import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:shelf/src/response.dart';

import '../../helpers.dart';

class SortAction implements Action {
  SortAction(this.validator);

  TriggeredByValidator validator;

  @override
  Future<Response> run({bool reset = false}) async {
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

    if (reset) {
      validator.game.playersSorted.clear();
      return SuccessResponse(
          {'gameId': validator.game.id, 'playerPosition': 0});
    } else {
      return _processSortRequest();
    }
  }

  Response _processSortRequest() {
    final validator2 = validator as TargetUserValidator;

    final playerToSort = validator.game.players[validator2.targetUserId];
    if (playerToSort == null) {
      return ErrorNotFoundResponse(
          'Player ${validator2.targetUserId} not found in game');
    }
    final position = int.parse(validator.validated['position'].toString());
    final sortPosition = sort(playerToSort, position, validator.game);
    if (sortPosition < 0) {
      return ErrorResponse('Unknown error during sorting');
    }

    return SuccessResponse({
      'gameId': validator.game.id,
      'playerPosition': sortPosition,
    });
  }

  static int sort(LitUser playerToSort, int position, LitGame game) {
    final playersSorted = game.playersSorted;
    if (playersSorted.length == 0) {
      playersSorted.add(LinkedUser(playerToSort));
      return 0;
    } else {
      try {
        final existing = playersSorted
            .firstWhere((element) => element.user.id == playerToSort.id);
        existing.unlink();
      } catch (_) {}

      if (position < 0) {
        playersSorted.addFirst(LinkedUser(playerToSort));
        return 0;
      } else if (position >= playersSorted.length) {
        playersSorted.add(LinkedUser(playerToSort));
        return playersSorted.length - 1;
      } else {
        var counter = 0;
        for (var sorted in playersSorted) {
          if (counter == position) {
            sorted.insertBefore(LinkedUser(playerToSort));
            return position;
          }
          counter++;
        }
      }
    }
    return -1;
  }
}
