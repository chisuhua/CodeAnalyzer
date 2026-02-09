#!/bin/bash
# Test script to verify the complete workflow

set -e

echo "==================================="
echo "CodeAnalyzer Workflow Test"
echo "==================================="
echo ""

# Check if extractor is built
if [ ! -f "build/inheritance_extractor" ]; then
    echo "Error: Extractor not built. Run ./build.sh first."
    exit 1
fi

# Create temporary files and set up cleanup trap
TEST_DOT=$(mktemp --suffix=.dot /tmp/test_graph.XXXXXX)
TEST_PNG=$(mktemp --suffix=.png /tmp/test_graph.XXXXXX)

cleanup() {
    rm -f "$TEST_DOT" "$TEST_PNG"
}
trap cleanup EXIT

# Test 1: Command-line extraction
echo "Test 1: Command-line extraction"
echo "--------------------------------"
echo "Running: ./build/inheritance_extractor test.cpp -- > graph.dot"
./build/inheritance_extractor test.cpp -- > "$TEST_DOT"
echo "✓ DOT file generated"
echo ""

# Verify DOT content
echo "DOT content:"
cat "$TEST_DOT"
echo ""

# Count nodes and edges
NODES=$(grep -E '^\s*"[^"]*";' "$TEST_DOT" | wc -l)
EDGES=$(grep -E '^\s*"[^"]*"\s*->\s*"[^"]*"' "$TEST_DOT" | wc -l)

echo "Statistics:"
echo "  - Nodes: $NODES"
echo "  - Edges: $EDGES"

if [ "$NODES" -eq 3 ] && [ "$EDGES" -eq 2 ]; then
    echo "✓ Expected node and edge count matches (3 nodes, 2 edges)"
else
    echo "✗ Unexpected node/edge count (expected 3 nodes, 2 edges)"
    exit 1
fi
echo ""

# Verify access specifiers
if grep -q 'label="public"' "$TEST_DOT" && grep -q 'label="private"' "$TEST_DOT"; then
    echo "✓ Access specifiers annotated correctly"
else
    echo "✗ Missing access specifier annotations"
    exit 1
fi
echo ""

# Test 2: Graphviz visualization
echo "Test 2: Graphviz visualization"
echo "--------------------------------"
echo "Running: dot -Tpng graph.dot -o graph.png"
dot -Tpng "$TEST_DOT" -o "$TEST_PNG"
echo "✓ PNG file generated"
ls -lh "$TEST_PNG"
echo ""

# Test 3: Python integration
echo "Test 3: Python integration"
echo "--------------------------------"
python3 << 'EOF'
import subprocess
import os

# Test the C++ extractor through Python
result = subprocess.run(
    ['./build/inheritance_extractor', 'test.cpp', '--'],
    capture_output=True,
    text=True
)

if result.returncode == 0:
    print("✓ Python can call C++ extractor successfully")
    
    # Check DOT output
    if "digraph InheritanceGraph" in result.stdout:
        print("✓ Valid DOT format output")
    else:
        print("✗ Invalid DOT output")
        exit(1)
        
    # Check for nodes
    if '"Animal"' in result.stdout and '"Dog"' in result.stdout and '"Cat"' in result.stdout:
        print("✓ All expected nodes present")
    else:
        print("✗ Missing expected nodes")
        exit(1)
        
    # Check for edges with access specifiers
    if 'label="public"' in result.stdout and 'label="private"' in result.stdout:
        print("✓ Access specifiers present in edges")
    else:
        print("✗ Access specifiers missing")
        exit(1)
else:
    print("✗ Failed to run extractor")
    exit(1)
EOF

# With set -e, the script will exit on failure, so we only reach here on success
echo ""
echo "==================================="
echo "All tests passed! ✓"
echo "==================================="
echo ""
echo "Acceptance criteria met:"
echo "  ✓ DOT output contains 3 nodes and 2 edges"
echo "  ✓ Access permissions annotated (public/private)"
echo "  ✓ Command-line: ./build/inheritance_extractor test.cpp --"
echo "  ✓ Graphviz PNG generation works"
echo ""
echo "To run the Streamlit UI:"
echo "  streamlit run main.py"
