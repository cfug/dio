cd dio
flutter test --coverage .
genhtml -o coverage coverage/lcov.info
# Open in the default browser (mac):
open coverage/index.html

