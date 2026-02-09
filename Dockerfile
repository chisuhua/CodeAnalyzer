FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    cmake \
    git \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install Clang 16
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 16 && \
    rm llvm.sh

# Install LLVM and Clang development libraries
RUN apt-get update && apt-get install -y \
    llvm-16-dev \
    libclang-16-dev \
    clang-16 \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# Set environment variables for LLVM
ENV LLVM_DIR=/usr/lib/llvm-16/lib/cmake/llvm
ENV Clang_DIR=/usr/lib/llvm-16/lib/cmake/clang
ENV PATH="/usr/lib/llvm-16/bin:${PATH}"

# Create working directory
WORKDIR /app

# Copy project files
COPY . /app/

# Install Python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install -r requirements.txt

# Build the C++ extractor
RUN mkdir -p build && \
    cd build && \
    cmake .. && \
    cmake --build .

# Expose Streamlit port
EXPOSE 8501

# Set default command to run Streamlit app
CMD ["streamlit", "run", "main.py", "--server.address", "0.0.0.0"]
