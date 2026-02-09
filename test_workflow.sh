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

# Test 1: Command-line extraction
echo "Test 1: Command-line extraction"
echo "--------------------------------"
echo "Running: ./build/inheritance_extractor test.cpp -- > graph.dot"
./build/inheritance_extractor test.cpp -- > /tmp/test_graph.dot
echo "✓ DOT file generated"
echo ""

# Verify DOT content
echo "DOT content:"
cat /tmp/test_graph.dot
echo ""

# Count nodes and edges
NODES=$(grep -E '^\s*"[^"]*";' /tmp/test_graph.dot | wc -l)
EDGES=$(grep -E '^\s*"[^"]*"\s*->\s*"[^"]*"' /tmp/test_graph.dot | wc -l)

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
if grep -q 'label="public"' /tmp/test_graph.dot && grep -q 'label="private"' /tmp/test_graph.dot; then
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
dot -Tpng /tmp/test_graph.dot -o /tmp/test_graph.png
echo "✓ PNG file generated"
ls -lh /tmp/test_graph.png
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

if [ $? -eq 0 ]; then
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
else
    echo "Tests failed!"
    exit 1
fi
