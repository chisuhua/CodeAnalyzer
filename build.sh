#!/bin/bash
# Build script for CodeAnalyzer

set -e

echo "=== Building CodeAnalyzer ==="
echo ""

# Check for required tools
echo "Checking dependencies..."
command -v cmake >/dev/null 2>&1 || { echo "Error: cmake is required but not installed."; exit 1; }
command -v clang++ >/dev/null 2>&1 || { echo "Error: clang++ is required but not installed."; exit 1; }

# Find LLVM version
LLVM_VERSION=$(ls -d /usr/lib/llvm-* 2>/dev/null | sort -V | tail -1 | sed 's/.*llvm-//')
if [ -z "$LLVM_VERSION" ]; then
    echo "Error: LLVM not found in /usr/lib/"
    exit 1
fi

echo "Found LLVM version: $LLVM_VERSION"

# Set environment variables
export LLVM_DIR=/usr/lib/llvm-${LLVM_VERSION}/lib/cmake/llvm
export PATH="/usr/lib/llvm-${LLVM_VERSION}/bin:${PATH}"

echo "LLVM_DIR: $LLVM_DIR"

# Create build directory
mkdir -p build
cd build

# Run CMake
echo ""
echo "Running CMake..."
cmake .. || exit 1

# Build
echo ""
echo "Building..."
cmake --build . || exit 1

echo ""
echo "=== Build completed successfully ==="
echo "Extractor binary: $(pwd)/inheritance_extractor"
