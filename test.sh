cd dio
openssl s_client \
  -servername sha256.badssl.com \
  -connect sha256.badssl.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -noout -fingerprint -sha256 > test/_pinning.txt 2>/dev/null
dart test --coverage=coverage .
pub run coverage:format_coverage --packages=.packages -i coverage -o coverage/lcov.info --lcov
genhtml -o coverage coverage/lcov.info
# Open in the default browser (mac):
open coverage/index.html
