# CMake Testing Framework Integration

## Summary

This CMake boilerplate provides an easy-to-use template for integrating testing frameworks into C++ projects. It supports 4 popular testing frameworks: doctest, Catch2, Google Test (gtest), and Boost.Test.

## Features Implemented

### 🎯 **Simple API**
- **One-time registration**: `register_test_framework(boost)` in main CMakeLists.txt
- **Add tests anywhere**: `register_test(MyTests)` in any subdirectory
- **Auto-discovery**: Tests are automatically found and configured

### 🔧 **Supported Frameworks**
- [**DocTest**](https://github.com/doctest/doctest)
- [**Catch2**](https://github.com/catchorg/Catch2)
- [**GTest**](https://github.com/google/googletest)
- [**Boost.Test**](https://github.com/boostorg/test)

## Key Files Modified

### Core Implementation
- `project/cmake/modules/ProjectBoilerplate.cmake`: Uses `register_test_framework()` and `register_test()` functions
- [hello_testing_frameworks](project/samples/hello_testing_frameworks): Shows simple test usage

## Usage Examples

### 1. Register Framework (once in main CMakeLists.txt)
```cmake
register_test_framework(doctest)  # or catch2, gtest, boost
```

### 2. Add Tests (anywhere in your project)
```cmake
register_test(MyAwesomeTests)  # Auto-discovers test_*.cpp files
```

### 3. Build and Test
```bash
cmake -S project -B build -DTEST_FRAMEWORK=gtest
cmake --build build
ctest --test-dir build
```
