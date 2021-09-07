import 'package:intl/intl.dart';

abstract class LoggerInterface {
  String get separator;

  void beginSection();

  void endSection();

  void log(Object message);
}

class ConsoleLogger implements LoggerInterface {
  @override
  void log(Object message) {
    var closeSection = false;
    if (!_sectionOpened) {
      beginSection();
      closeSection = true;
    }
    print('> ' + message.toString());
    if (closeSection) {
      endSection();
    }
  }

  bool _sectionOpened = false;

  @override
  void beginSection() {
    final now = DateFormat('yyyy-MM-dd H:i:s').format(DateTime.now());
    print(separator + now + separator);
    _sectionOpened = true;
  }

  @override
  void endSection() {
    print(separator + 'END' + separator + "\n" + "\n");
    _sectionOpened = false;
  }

  @override
  String get separator => '========';
}
