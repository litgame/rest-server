import 'package:litgame_server/service/logger.dart';
import 'package:shelf/shelf.dart';

abstract class Action {
  Action(this._logger);

  Future<Response> run();

  LoggerInterface _logger;
  LoggerInterface get logger => _logger;
}
