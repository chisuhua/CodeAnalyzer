#!/usr/bin/env python3
"""
C++ Inheritance Analyzer - Streamlit UI
Uploads C++ files, extracts inheritance relationships, and visualizes them.
"""

import os
import subprocess
import tempfile
import streamlit as st
from pathlib import Path

# Configure page
st.set_page_config(
    page_title="C++ Inheritance Analyzer",
    page_icon="🔍",
    layout="wide"
)

def run_cpp_extractor(cpp_file_path):
    """
    Run the C++ inheritance extractor and generate DOT format.
    
    Args:
        cpp_file_path: Path to the C++ source file
        
    Returns:
        tuple: (dot_content, error_message)
    """
    try:
        # Find the extractor executable
        extractor_path = Path("build/inheritance_extractor")
        if not extractor_path.exists():
            extractor_path = Path("inheritance_extractor")
        
        if not extractor_path.exists():
            return None, "Error: inheritance_extractor not found. Please build the project first."
        
        # Run the extractor
        result = subprocess.run(
            [str(extractor_path), cpp_file_path, "--"],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            return None, f"Extractor failed: {result.stderr}"
        
        return result.stdout, None
        
    except subprocess.TimeoutExpired:
        return None, "Error: Extraction timed out"
    except Exception as e:
        return None, f"Error running extractor: {str(e)}"

def generate_png_from_dot(dot_content):
    """
    Generate PNG image from DOT format using Graphviz.
    
    Args:
        dot_content: DOT format string
        
    Returns:
        Path to generated PNG file or None on error
    """
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.dot', delete=False) as dot_file:
            dot_file.write(dot_content)
            dot_path = dot_file.name
        
        png_path = dot_path.replace('.dot', '.png')
        
        # Run Graphviz dot command
        result = subprocess.run(
            ['dot', '-Tpng', dot_path, '-o', png_path],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Clean up DOT file
        os.unlink(dot_path)
        
        if result.returncode != 0:
            st.error(f"Graphviz error: {result.stderr}")
            return None
        
        return png_path
        
    except Exception as e:
        st.error(f"Error generating PNG: {str(e)}")
        return None

def main():
    st.title("🔍 C++ Inheritance Analyzer")
    st.markdown("""
    Upload a C++ source file to extract and visualize its class inheritance relationships.
    
    **Features:**
    - Extract inheritance relationships from C++ code
    - Generate DOT graph format
    - Visualize inheritance hierarchy with Graphviz
    - Annotate with access specifiers (public/private/protected)
    """)
    
    # File uploader
    uploaded_file = st.file_uploader(
        "Choose a C++ file",
        type=['cpp', 'cc', 'cxx', 'h', 'hpp'],
        help="Upload a C++ source or header file"
    )
    
    if uploaded_file is not None:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(mode='wb', suffix='.cpp', delete=False) as tmp_file:
            tmp_file.write(uploaded_file.getvalue())
            tmp_path = tmp_file.name
        
        try:
            # Display file content
            with st.expander("📄 View Source Code"):
                file_content = uploaded_file.getvalue().decode('utf-8')
                st.code(file_content, language='cpp')
            
            # Extract inheritance relationships
            with st.spinner("Extracting inheritance relationships..."):
                dot_content, error = run_cpp_extractor(tmp_path)
            
            if error:
                st.error(error)
            elif dot_content:
                # Create two columns for visualization and DOT source
                col1, col2 = st.columns([2, 1])
                
                with col1:
                    st.subheader("📊 Inheritance Graph")
                    # Generate and display PNG
                    with st.spinner("Generating visualization..."):
                        png_path = generate_png_from_dot(dot_content)
                    
                    if png_path:
                        st.image(png_path, use_column_width=True)
                        # Clean up PNG file
                        os.unlink(png_path)
                    else:
                        st.warning("Could not generate visualization")
                
                with col2:
                    st.subheader("📝 DOT Source")
                    st.code(dot_content, language='dot')
                    
                    # Download button for DOT file
                    st.download_button(
                        label="⬇️ Download DOT",
                        data=dot_content,
                        file_name="inheritance_graph.dot",
                        mime="text/plain"
                    )
                
            else:
                st.warning("No inheritance relationships found in the file.")
        
        finally:
            # Clean up temporary file
            os.unlink(tmp_path)
    
    # Show example
    with st.expander("💡 Example Usage"):
        st.markdown("""
        **Example C++ code:**
        ```cpp
        class Animal {
        public:
            virtual void speak() {}
        };

        class Dog : public Animal {
        public:
            void speak() override {}
        };

        class Cat : private Animal {
        public:
            void speak() override {}
        };
        ```
        
        **Expected output:**
        - 3 nodes: Animal, Dog, Cat
        - 2 edges: Dog → Animal (public), Cat → Animal (private)
        """)
    
    # Command-line usage
    with st.expander("⌨️ Command-Line Usage"):
        st.markdown("""
        You can also use the extractor from the command line:
        
        ```bash
        ./build/inheritance_extractor test.cpp -- > graph.dot
        dot -Tpng graph.dot -o graph.png
        ```
        """)

if __name__ == "__main__":
    main()
