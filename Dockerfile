FROM google/dart:2.13-beta
WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline
RUN chmod +x bin/runserver.sh

ENTRYPOINT [ "/usr/lib/dart/bin/dart", "run", "/app/bin/server.dart" ]