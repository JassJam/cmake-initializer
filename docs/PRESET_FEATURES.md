# Preset-Based Configuration Features

This document describes the advanced preset-based configuration features that automate test framework registration and CTest dashboard uploads.

## Auto Test Framework Registration

### Overview
Define `DEFAULT_TEST_FRAMEWORK` in your CMake preset to automatically register a testing framework without manual `register_test_framework()` calls.

### Supported Frameworks
- `doctest`
- `catch2`
- `gtest`
- `boost`

### Example Configuration

```json
{
    ...
    "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "DEFAULT_TEST_FRAMEWORK": "gtest"
    }
}
```

## CTest Dashboard Upload

### Overview
Configure automatic test result uploads to CTest dashboards (CDash, etc.) directly from presets.

### Configuration Methods

#### Method 1: Separate Site and Location (Legacy Compatible)
```json
{
    "cacheVariables": {
        "CTEST_DROP_SITE_PRESET": "my.cdash.org",
        "CTEST_DROP_LOCATION_PRESET": "/submit.php?project=MyProject",
        "CTEST_DROP_METHOD": "https"
    }
}
```

#### Method 2: Complete URL (CMake 3.14+)
```json
{
    "cacheVariables": {
        "CTEST_SUBMIT_URL_PRESET": "https://my.cdash.org/submit.php?project=MyProject"
    }
}
```

### Additional Configuration

#### Test Timeout
```json
{
    "cacheVariables": {
        "CTEST_TEST_TIMEOUT_PRESET": "300"
    }
}
```

#### HTTP Protocol Selection
```json
{
    "cacheVariables": {
        "CTEST_DROP_METHOD": "https"
    }
}
```
*Note: Defaults to "https" if not specified*

### GitHub Actions Integration

#### Repository Secrets
Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Example Value | Description |
|-------------|---------------|-------------|
| `CTEST_DASHBOARD_SITE` | `my.cdash.org` | Dashboard hostname |
| `CTEST_DASHBOARD_LOCATION` | `/submit.php?project=MyProject` | Upload endpoint path |
| `CTEST_SUBMIT_URL_PRESET` | `https://my.cdash.org/submit.php?project=MyProject` | Complete URL for CTest submission |
| `CTEST_TEST_TIMEOUT_PRESET` | `300` | Test timeout in seconds |
| `CTEST_DROP_METHOD` | `https` | HTTP protocol for uploads |

## Available Presets

| Platform | Development | Testing | Production |
|----------|-------------|---------|------------|
| **Windows** | `windows-[clang\|msvc]-debug` | `test-windows-[clang\|msvc]-[debug\|release]` | `windows-[clang\|msvc]-release` |
| **Linux** | `unixlike-[gcc\|clang]-debug` | `unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |
| **macOS** | `unixlike-[gcc\|clang]-debug` | `unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |

### Usage
```bash
# Configure with a 'unixlike-clang-debug' preset
cmake -S ./project -B build --preset unixlike-clang-debug

# Configure with a 'test-windows-msvc-debug' preset
cmake -S ./project -B build --preset test-windows-msvc-debug
```
