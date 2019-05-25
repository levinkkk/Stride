#!/bin/bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  echo $(swift --version)
  YOGA_LIB_PATH=$PWD/$(find . -wholename '*/Sources/Yoga/linux*' | head -n 1)
  echo "Using Yoga in: $YOGA_LIB_PATH"

  CLIPBOARD_LIB_PATH=$PWD/$(find . -wholename '*/Sources/CClipboard' | head -n 1)
  echo "Using Clipboard in: $CLIPBOARD_LIB_PATH"

  swift build -Xlinker -lxcb-util -Xlinker -lxcb -Xlinker -lstdc++ -Xswiftc -L$YOGA_LIB_PATH -Xswiftc -L$CLIPBOARD_LIB_PATH
  EXIT_STATUS=$?
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH
  echo $(swift --version)
  YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga/darwin*' | head -n 1)
  echo "Using Yoga in: $YOGA_LIB_PATH"
  swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
  EXIT_STATUS=$?
else
  echo "Error: unsupported platform."
fi

OUTPUT_DIR=$(swift build --show-bin-path)

echo "Installing assets into $OUTPUT_DIR"
cp -R Assets $OUTPUT_DIR

exit $EXIT_STATUS