# CDash Integration Guide

This document describes the CI/CD CDash integration for the cmake-initializer project.

## Overview

The cmake-initializer project provides comprehensive CDash integration designed for CI/CD pipelines with secure authentication support. Test results are automatically submitted to your CDash dashboard during the CI process.

## Secrets for CDash Submission

| Secret Name | Description | Required | Default Value |
|-------------|-------------|----------|---------------|
| `CTEST_DASHBOARD_SITE` | CDash server URL (e.g., `my.cdash.org`) | Required | None |
| `CTEST_DASHBOARD_LOCATION` | CDash submit path (e.g., `/submit.php?project=MyProject`) | Required | None |
| `CDASH_AUTH_TOKEN` | Bearer token for CDash authentication | Optional | None (no auth) |
| `CTEST_DASHBOARD_MODEL` | Dashboard model: `Continuous`, `Nightly`, or `Experimental` | Optional | `Continuous` |
| `CTEST_DROP_METHOD` | HTTP protocol for uploads | Optional | `https` |
| `CTEST_TEST_TIMEOUT_PRESET` | Test timeout in seconds | Optional | `300` (5 minutes) |

**Setup:**
1. Go to your repository Settings → Secrets and variables → Actions
2. Add the above secrets with your CDash configuration
3. Push code or create a pull request
4. Check the Actions tab for CDash submission results
