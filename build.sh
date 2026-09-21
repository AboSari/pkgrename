#!/usr/bin/env bash
set -e

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/pkgrename.c" ]; then
    SRC_DIR="$SCRIPT_DIR"
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -d "$SCRIPT_DIR/pkgrename.c" ]; then
    SRC_DIR="$SCRIPT_DIR/pkgrename.c"
    ROOT_DIR="$SCRIPT_DIR"
else
    SRC_DIR="$(pwd)"
    ROOT_DIR="$(pwd)"
fi

cd "$SRC_DIR"

TARGET="${1:-windows}"

build_windows() {
    echo "==> Building pkgrename.exe for Windows..."
    
    # Detect MinGW compiler
    MINGW_CC=""
    if command -v x86_64-w64-mingw32-gcc-win32 >/dev/null 2>&1; then
        MINGW_CC="x86_64-w64-mingw32-gcc-win32"
    elif command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
        MINGW_CC="x86_64-w64-mingw32-gcc"
    fi

    if [ -z "$MINGW_CC" ]; then
        echo "Error: MinGW compiler (x86_64-w64-mingw32-gcc-win32) not found."
        echo "Install it on Ubuntu/Debian using: sudo apt install gcc-mingw-w64-x86-64"
        return 1
    fi

    echo "Using compiler: $MINGW_CC"
    $MINGW_CC -Wall -Wextra -pedantic pkgrename.c src/*.c -o pkgrename.exe -static -pthread -s -O3

    # Copy output to repo root if different
    if [ "$SRC_DIR" != "$ROOT_DIR" ]; then
        cp -f "$SRC_DIR/pkgrename.exe" "$ROOT_DIR/pkgrename.exe"
    fi

    echo "Successfully built Windows binary:"
    echo "  -> $SRC_DIR/pkgrename.exe"
    if [ "$SRC_DIR" != "$ROOT_DIR" ]; then
        echo "  -> $ROOT_DIR/pkgrename.exe"
    fi
}

build_linux() {
    echo "==> Building pkgrename for Linux..."
    
    if ! command -v gcc >/dev/null 2>&1; then
        echo "Error: gcc not found."
        return 1
    fi

    # Check for curl headers
    if ! echo '#include <curl/curl.h>' | gcc -E - >/dev/null 2>&1; then
        echo "Error: libcurl development headers (<curl/curl.h>) not found."
        echo "Install them using:"
        echo "  sudo apt update && sudo apt install -y libcurl4-openssl-dev"
        return 1
    fi

    gcc -Wall -Wextra -pedantic pkgrename.c src/*.c -o pkgrename -lcurl -pthread -s -O3

    if [ "$SRC_DIR" != "$ROOT_DIR" ]; then
        cp -f "$SRC_DIR/pkgrename" "$ROOT_DIR/pkgrename"
    fi

    echo "Successfully built Linux binary:"
    echo "  -> $SRC_DIR/pkgrename"
    if [ "$SRC_DIR" != "$ROOT_DIR" ]; then
        echo "  -> $ROOT_DIR/pkgrename"
    fi
}

case "$TARGET" in
    windows|win|exe)
        build_windows
        ;;
    linux)
        build_linux
        ;;
    all)
        build_windows
        echo ""
        build_linux
        ;;
    clean)
        echo "Cleaning build artifacts..."
        rm -f "$SRC_DIR/pkgrename" "$SRC_DIR/pkgrename.exe"
        rm -f "$ROOT_DIR/pkgrename.exe"
        echo "Cleaned."
        ;;
    help|-h|--help)
        echo "Usage: $0 [windows|linux|all|clean]"
        echo "Default target is 'windows' (builds pkgrename.exe)."
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [windows|linux|all|clean]"
        exit 1
        ;;
esac
