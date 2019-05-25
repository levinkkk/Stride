YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga' | head -n 1)
echo "Using Yoga in: $YOGA_LIB_PATH"

swift test --generate-linuxmain -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
