import 'dart:collection';

class LitUser {
  LitUser(this.id, {this.isAdmin = false, this.isGameMaster = false});

  bool isGameMaster = false;
  bool isAdmin = false;
  String id;

  bool get isEmpty => id == 'empty';

  bool get isNotEmpty => id != 'empty';

  @override
  bool operator ==(Object other) => other is LitUser && other.id == id;

  Map toJson() => {'id': id, 'isAdmin': isAdmin, 'isGameMaster': isGameMaster};
}

class LinkedUser extends LinkedListEntry<LinkedUser> {
  LinkedUser(this.user);

  final LitUser user;

  Map toJson() => user.toJson();
}
