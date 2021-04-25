import 'package:shelf/shelf.dart';

abstract class Action {
  Future<Response> run();
}
