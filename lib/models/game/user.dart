// ignore_for_file: import_of_legacy_library_into_null_safe
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';

import '../../redis.dart';
import 'game.dart';

//TODO: heavy refactoring needed
class LitUser extends ParseObject implements ParseCloneable {
  static late List<int> adminUsers;
  static final Map<String, Map<String, dynamic>> _usersDataCache = {};

  LitUser.clone()
      : id = 'empty',
        super('LitUser');

  LitUser.byId(String userId)
      : id = userId,
        super('LitUser') {
    registrationChecked = _findInStorage();
    this['userId'] = id;
  }

  @override
  LitUser clone(Map<String, dynamic> map) => LitUser.clone()..fromJson(map);

  LitUser(this.id, {this.isAdmin = false, this.isGameMaster = false})
      : super('LitUser') {
    if (isNotEmpty) {
      registrationChecked = _findInStorage();
      this['userId'] = id;
    }
  }

  late Future<bool> registrationChecked;
  bool isGameMaster = false;
  bool isAdmin = false;
  String id;

  bool get isEmpty => id == 'empty';
  bool get isNotEmpty => id != 'empty';

  LitGame? currentGame;

  @override
  bool operator ==(Object other) => other is LitUser && other.id == id;

  Future<ParseResponse> allowAddCollection(bool allow) {
    this['allowAddCollection'] = allow;
    return save();
  }

  @override
  Future<ParseResponse> save() {
    final redis = Redis();
    redis.init.then((_) {
      redis.commands.set('userId-$id', toRedis());
    });
    return super.save();
  }

  bool get isAllowedAddCollection => this['allowAddCollection'] ?? false;

  Future<bool> _findInStorage() async {
    var found = false;
    found = await _findInMemory();
    if (!found) {
      found = await _findInRedis();
      if (!found) {
        found = await _findInParse();
      }
    }
    return found;
  }

  Future<bool> _findInMemory() {
    final searchFinished = Completer<bool>();
    final userData = _usersDataCache[id];
    if (userData == null) {
      searchFinished.complete(false);
      return searchFinished.future;
    }
    this['objectId'] = userData['objectId'] ?? -1;
    this['allowAddCollection'] = userData['allowAddCollection'] ?? false;
    if (this['allowAddCollection'] is String) {
      this['allowAddCollection'] =
          this['allowAddCollection'] == 'true' ? true : false;
    }
    this['copychat'] = userData['copychat'] ?? false;
    if (this['copychat'] is String) {
      this['copychat'] = this['copychat'] == 'true' ? true : false;
    }
    searchFinished.complete(true);
    return searchFinished.future;
  }

  void _saveToMemory() {
    if (_usersDataCache.length > 10000) {
      var keysToDelete = <String>[];
      _usersDataCache.forEach((key, value) {
        final ts = value['ts'] as DateTime;
        if (DateTime.now().difference(ts).inDays > 10) {
          keysToDelete.add(key);
        }
      });
      keysToDelete.forEach((element) {
        _usersDataCache.remove(element);
      });
    }

    _usersDataCache[id] = {
      'copychat': this['copychat'] ?? false.toString(),
      'allowAddCollection': this['allowAddCollection'] ?? false.toString(),
      'objectId': this['objectId'] ?? (-1).toString(),
      'ts': DateTime.now()
    };
  }

  Future<bool> _findInRedis() {
    final redis = Redis();
    final searchFinished = Completer<bool>();
    var timeout = false;
    redis.init.then((_) {
      redis.commands.get('userId-' + id.toString()).then((value) {
        if (value == null || timeout) {
          if (!searchFinished.isCompleted) {
            searchFinished.complete(false);
          }
          return;
        }
        fromRedis(value);
        _saveToMemory();
        if (!searchFinished.isCompleted) {
          searchFinished.complete(true);
        }
      });
    });
    Future.delayed(Duration(milliseconds: 10)).then((_) {
      if (!searchFinished.isCompleted) {
        searchFinished.complete(false);
      }
      timeout = true;
    });
    return searchFinished.future;
  }

  void _saveToRedis() {
    final redis = Redis();
    redis.init.then((_) {
      redis.commands.set('userId-$id', toRedis());
    });
  }

  Future<bool> _findInParse() {
    final builder = QueryBuilder<LitUser>(LitUser.clone())
      ..whereEqualTo('userId', id);
    return builder.query().then((ParseResponse response) {
      final results = response.results;
      if (results == null) return false;
      if (results.isNotEmpty) {
        this['objectId'] = results.first['objectId'];
        this['allowAddCollection'] = results.first['allowAddCollection'];
        this['copychat'] = results.first['copychat'];
        _saveToMemory();
        _saveToRedis();
        return true;
      }
      return false;
    });
  }

  String toRedis() {
    final _json = <String, String>{};
    _json['objectId'] = this['objectId'] ?? (-1).toString();
    _json['allowAddCollection'] =
        (this['allowAddCollection'] ?? false).toString();
    _json['copychat'] = (this['copychat'] ?? false).toString();
    return jsonEncode(_json);
  }

  void fromRedis(String value) {
    final _json = jsonDecode(value);
    this['objectId'] = _json['objectId'] ?? -1;
    this['allowAddCollection'] = _json['allowAddCollection'] ?? false;
    this['copychat'] = _json['copychat'] ?? false;
  }
}

class LinkedUser extends LinkedListEntry<LinkedUser> {
  LinkedUser(this.user);

  final LitUser user;
}
