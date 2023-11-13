#!/usr/bin/bash

while [[ "$1" == -* ]]; do
  case "$1" in
    --platform=*)      PLATFORM="${1#*=}"; shift;;
    --help|-h)         echo ""
                       echo "Run Dart tests on the specific platform."
                       echo ""
                       echo "Usage: $(basename $0) [options]"
                       echo ""
                       echo "  --platform   Run tests on the specific platform"
                       echo "  -h, --help   Print this usage information"
                       echo "";
                       exit 0;;
    *)                 echo "Unrecognized option: $1. Use --help for usage."; exit 0;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "--platform is required."
  exit 1
fi

dart test --chain-stack-traces --platform="$PLATFORM"

exit_code=$?

## Escape 79 which means no tests run on the specific platform.
if [ $exit_code -eq 79 ]; then
    exit 0
else
    exit $exit_code
fi
