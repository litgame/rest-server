import 'dart:io';

import 'package:litgame_server/models/cards/card.dart';
import 'package:litgame_server/models/cards/card_collection.dart';
import 'package:litgame_server/service/logger.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api/collection.dart';
import 'api/main.dart';
import 'helpers.dart';

abstract class RestService {
  Router get router;
  LoggerInterface get logger;
}

class LitGameRestService {
  static bool debugMode = false;

  LitGameRestService() {
    final envVars = Platform.environment;
    var useDefault = false;
    final _dataAppUrl = envVars['BOT_PARSESERVER_URL'];
    if (_dataAppUrl == null) useDefault = true;

    final _dataAppKey = envVars['BOT_PARSESERVER_APP_KEY'];
    if (_dataAppKey == null) useDefault = true;

    final _parseMasterKey = envVars['BOT_PARSESERVER_MASTER_KEY'];
    if (_parseMasterKey == null) useDefault = true;

    final _parseRestKey = envVars['BOT_PARSESERVER_REST_KEY'];
    if (_parseRestKey == null) useDefault = true;

    if (envVars['BOT_DEBUG_MODE'] == 'true') {
      debugMode = true;
    }

    if (useDefault) {
      init = Parse().initialize(
        'appId',
        'https://test.parse.com',
        debug: true,
        // to prevent automatic detection
        fileDirectory: 'someDirectory',
        // to prevent automatic detection
        appName: 'appName',
        // to prevent automatic detection
        appPackageName: 'somePackageName',
        // to prevent automatic detection
        appVersion: 'someAppVersion',
      );
    } else {
      init = Parse().initialize(
        _dataAppKey as String,
        _dataAppUrl as String,
        masterKey: _parseMasterKey,
        clientKey: _parseRestKey,
        debug: true,
        registeredSubClassMap: <String, ParseObjectConstructor>{
          'Card': () => Card.clone(),
          'CardCollection': () => CardCollection.clone(),
        },
        // to prevent automatic detection
        fileDirectory: 'someDirectory',
        // to prevent automatic detection
        appName: 'appName',
        // to prevent automatic detection
        appPackageName: 'somePackageName',
        // to prevent automatic detection
        appVersion: 'someAppVersion',
      );
    }
  }

  LitGameRestService.manual(String parseServerUrl, String parseServerAppKey,
      String? parseServerMasterKey, String parseServerRestKey) {
    init = Parse().initialize(
      parseServerAppKey,
      parseServerUrl,
      debug: false,
      masterKey: parseServerMasterKey,
      clientKey: parseServerRestKey,
      registeredSubClassMap: <String, ParseObjectConstructor>{
        'Card': () => Card.clone(),
        'CardCollection': () => CardCollection.clone(),
      },
      // to prevent automatic detection
      fileDirectory: 'someDirectory',
      // to prevent automatic detection
      appName: 'appName',
      // to prevent automatic detection
      appPackageName: 'somePackageName',
      // to prevent automatic detection
      appVersion: 'someAppVersion',
    );
  }

  late final Future init;

  Handler get handler {
    final router = Router();

    router.get('/', _version);
    router.get('/version', _version);

    router.mount('/api/game/', ApiMainService().router);
    router.mount('/api/collection/', ApiCollectionService().router);

    return router;
  }

  Response _version(Request request) {
    return Response.ok({'version': '1.0'}.toJson(), headers: jsonHttpHeader);
  }
}
