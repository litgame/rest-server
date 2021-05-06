import 'package:litgame_server/models/game/game.dart';
import 'package:litgame_server/models/game/user.dart';
import 'package:litgame_server/service/api/actions/core.dart';
import 'package:shelf/shelf.dart';

import '../../helpers.dart';

class KickAction implements Action {
  KickAction(this.game, this.triggeredBy, this.targetUserId, this.jsonRequest);

  final LitGame game;
  final String triggeredBy;
  final String targetUserId;

  final Map<String, dynamic> jsonRequest;

  String? get newAdminId => jsonRequest['newAdminId'];

  String? get newMasterId => jsonRequest['newMasterId'];

  Future<Response> run() async {
    if (triggeredBy == targetUserId) {
      return _kickSelf();
    } else {
      return _kickAnother();
    }
  }

  Future<Response> _kickSelf() async {
    if (game.state == GameState.join) {
      if (game.admin.id == targetUserId) {
        game.stop();
        return SuccessResponse({'gameId': game.id, 'status': 'finished'});
      } else {
        game.removePlayer(LitUser(targetUserId));
        return SuccessResponse({'userId': targetUserId, 'removed': true});
      }
    } else {
      if (game.admin.id == targetUserId) {
        final fail = await _setNewAdmin();
        if (fail != null) {
          return fail;
        }
        game.removePlayer(LitUser(targetUserId));
        return SuccessResponse(
            {'userId': targetUserId, 'removed': true, 'newAdmin': newAdminId});
      }
      if (game.master.id == targetUserId) {
        final fail = await _setNewMaster();
        if (fail != null) {
          return fail;
        }
        game.removePlayer(LitUser(targetUserId));
        return SuccessResponse({
          'userId': targetUserId,
          'removed': true,
          'newMaster': newMasterId
        });
      }

      game.removePlayer(LitUser(targetUserId));
      return SuccessResponse({
        'userId': targetUserId,
        'removed': true,
      });
    }
  }

  Future<Response?> _setNewAdmin() async {
    if (newAdminId == null || newAdminId.toString().isEmpty) {
      return ErrorResponse(
          'Cant kick admin without replacement. Please, provide "newAdmin" parameter');
    }
    final newAdmin = game.players[newAdminId.toString()];
    if (newAdmin == null) {
      return ErrorNotFoundResponse(
          'Specified admin $newAdminId does not involved into the game');
    }
    newAdmin.isAdmin = true;
    if (game.master.id == targetUserId) {
      newAdmin.isGameMaster = true;
    }
    return null;
  }

  Future<Response?> _setNewMaster() async {
    if (newMasterId == null || newMasterId.toString().isEmpty) {
      return ErrorResponse(
          'Cant kick master without replacement. Please, provide "newMaster" parameter');
    }
    final newMaster = game.players[newMasterId.toString()];
    if (newMaster == null) {
      return ErrorNotFoundResponse(
          'Specified master $newMasterId does not involved into the game');
    }
    newMaster.isGameMaster = true;
    return null;
  }

  Future<Response> _kickAnother() async {
    if (game.admin.id != triggeredBy) {
      return ErrorAccessResponse('Only admin can kick users');
    }

    final body = {
      'userId': targetUserId,
      'removed': true,
    };

    if (game.state == GameState.join) {
      game.removePlayer(LitUser(targetUserId));
      return SuccessResponse(body);
    } else {
      if (targetUserId == game.master.id) {
        final fail = await _setNewMaster();
        if (fail != null) {
          return fail;
        }
        body['newMaster'] = newMasterId as String;
      }
      if (game.state == GameState.training &&
          game.trainingFlow?.currentUser.id == targetUserId) {
        game.trainingFlow?.nextTurn();
        body['nextTurnByUserId'] =
            game.trainingFlow?.currentUser.id.toString() as String;
      } else if (game.state == GameState.game &&
          game.gameFlow?.currentUser.id == targetUserId) {
        body['nextTurnByUserId'] =
            game.gameFlow?.currentUser.id.toString() as String;
        game.gameFlow?.nextTurn();
      }

      game.removePlayer(LitUser(targetUserId));
      return SuccessResponse(body);
    }
  }
}
