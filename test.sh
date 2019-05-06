cd package_src
pwd
pub get
pub run test
pub global activate coverage
dart --enable-vm-service=8111 --pause-isolates-on-exit test/dio_test.dart
pub global run coverage:collect_coverage --port=8111 --out=coverage.json --wait-paused --resume-isolates
pub global run coverage:format_coverage --lcov --in=coverage.json --out=lcov.info --packages=.packages --report-on=lib
