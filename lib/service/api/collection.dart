import 'package:litgame_server/models/cards/card_collection.dart';
import 'package:litgame_server/service/helpers.dart';
import 'package:litgame_server/service/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';

import '../service.dart';

class ApiCollectionService implements RestService {
  @override
  Router get router {
    final router = Router();

    router.get('/list', _list);

    return router;
  }

  /// Returns collection JSON in format:
  /// ```json
  /// {
  ///     "collections": [
  ///         {
  ///             "className": "CardCollection",
  ///             "objectId": "123",
  ///             "createdAt": "2020-12-03T00:57:54.018Z",
  ///             "updatedAt": "2020-12-03T00:57:54.018Z",
  ///             "name": "Human Readable name"
  ///         },
  ///         {
  ///             "className": "CardCollection",
  ///             "objectId": "456",
  ///             "createdAt": "2021-01-23T15:47:45.695Z",
  ///             "updatedAt": "2021-01-23T15:47:45.695Z",
  ///             "name": "Another Name"
  ///         }
  ///     ]
  ///     "total": 2
  /// }
  /// ```
  ///
  Future<Response> _list(Request request) async {
    try {
      final list = await CardCollection.listCollections();
      return SuccessResponse({'collections': list, 'total': list.length});
    } catch (error) {
      return SuccessResponse({'collections': [], 'total': 0});
    }
  }

  @override
  LoggerInterface get logger => ConsoleLogger();
}
