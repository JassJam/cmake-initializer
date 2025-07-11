# CDash Integration Guide

This document describes the CI/CD CDash integration for the cmake-initializer project.

## Overview

The cmake-initializer project provides comprehensive CDash integration designed for CI/CD pipelines with secure authentication support. Test results are automatically submitted to your CDash dashboard during the CI process.

## CI/CD Integration

### GitHub Actions (Automatic)

The project automatically submits to CDash when you configure these repository secrets:

| Secret Name | Description |
|-------------|-------------|
| `CDASH_AUTH_TOKEN` | Your CDash authentication token |
| `CTEST_DASHBOARD_SITE` | CDash server hostname |
| `CTEST_DASHBOARD_LOCATION` | Submit endpoint path |
| `CTEST_DROP_METHOD` | HTTP protocol (default: `https`) |

**Setup:**
1. Go to your repository Settings → Secrets and variables → Actions
2. Add the above secrets with your CDash configuration
3. Push code or create a pull request
4. Check the Actions tab for CDash submission results
