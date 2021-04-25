import 'user.dart';

abstract class FlowInterface {
  void nextTurn();
  LitUser get currentUser;
}
