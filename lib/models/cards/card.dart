// ignore_for_file: import_of_legacy_library_into_null_safe
import 'package:parse_server_sdk/parse_server_sdk.dart';

enum CardType { generic, person, place }

extension StringType on CardType {
  String value() {
    switch (this) {
      case CardType.generic:
        return 'generic';
      case CardType.person:
        return 'person';
      case CardType.place:
        return 'place';
    }
  }

  CardType getTypeByName(String name) {
    switch (name) {
      case 'generic':
        return CardType.generic;
      case 'person':
        return CardType.person;
      case 'place':
        return CardType.place;
    }
    throw 'No such type: ' + name;
  }
}

class Card extends ParseObject implements ParseCloneable {
  Card(String name, String imgUrl, CardType cardType, String collectionName)
      : super('Card') {
    this['name'] = name;
    this['imgUrl'] = imgUrl;
    this['cardType'] = cardType.value();
    this['collection'] = collectionName;
  }

  Card.clone() : super('Card');

  @override
  Card clone(Map<String, dynamic> map) => Card.clone()..fromJson(map);

  String get name => this['name'];

  String get imgUrl {
    try {
      final parseFile = this['img'] as ParseFileBase;
      final url = parseFile.url;
      if (url == null) {
        return '';
      }
      return url;
    } catch (_) {
      return this['imgUrl'] ?? '';
    }
  }

  String get collectionName => this['collection'];

  CardType get cardType => CardType.generic.getTypeByName(this['cardType']);

  @override
  Map<String, dynamic> toJson(
      {bool full = false,
      bool forApiRQ = false,
      bool allowCustomObjectId = false}) {
    final map = super.toJson(
        full: full,
        forApiRQ: forApiRQ,
        allowCustomObjectId: allowCustomObjectId);
    map['imgUrl'] = this.imgUrl;
    return map;
  }
}
