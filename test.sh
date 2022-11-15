cd dio || exit
dart test --coverage=coverage .
pub run coverage:format_coverage --packages=.packages -i coverage -o coverage/lcov.info --lcov
genhtml -o coverage coverage/lcov.info
# Open in the default browser (mac):
open coverage/index.html
