FROM dart:2.19
ADD pubspec.yaml ./
RUN dart pub get
FROM scratch