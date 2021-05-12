import 'package:litgame_server/service/api/validators/triggered_by.dart';
import 'package:shelf/shelf.dart';

import '../../helpers.dart';

class TargetUserValidator extends TriggeredByValidator {
  TargetUserValidator(Request request, Map<String, BodyItemValidator?> rules)
      : super(
            request,
            {
              'targetUserId': (value, _) {
                if (value.toString().isEmpty) {
                  return "Can't kick user without 'targetUser' id";
                }
              }
            }..addEntries(rules.entries));

  String get targetUserId => validated['targetUserId'];
}
