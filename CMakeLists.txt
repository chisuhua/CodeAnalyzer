cmake_minimum_required(VERSION 3.16)
project(CodeAnalyzer)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find LLVM and Clang
find_package(LLVM REQUIRED CONFIG)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# Find clang libraries
find_library(CLANG_CPP_LIB 
    NAMES clang-cpp libclang-cpp libclang-cpp.so.${LLVM_VERSION_MAJOR}.${LLVM_VERSION_MINOR}
    PATHS ${LLVM_LIBRARY_DIRS} 
    NO_DEFAULT_PATH
)

if(NOT CLANG_CPP_LIB)
    message(FATAL_ERROR "Could not find clang-cpp library in ${LLVM_LIBRARY_DIRS}")
endif()

message(STATUS "Found clang-cpp: ${CLANG_CPP_LIB}")

# Add Clang include directories
set(CLANG_INCLUDE_DIR "${LLVM_INCLUDE_DIRS}/../include")
if(EXISTS "${CLANG_INCLUDE_DIR}/clang")
    include_directories(${CLANG_INCLUDE_DIR})
    message(STATUS "Found Clang headers: ${CLANG_INCLUDE_DIR}")
else()
    message(FATAL_ERROR "Could not find Clang headers")
endif()

# Add the inheritance extractor executable
add_executable(inheritance_extractor
    src/inheritance_extractor.cpp
)

# Link against LLVM and Clang libraries
target_link_libraries(inheritance_extractor
    ${CLANG_CPP_LIB}
    LLVM
)
