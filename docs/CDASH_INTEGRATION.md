# CDash Integration Guide

CDash integration for automated test result submission in CI/CD pipelines.

## Overview

The cmake-initializer provides CDash integration designed for CI/CD environments with secure authentication support. Test results are automatically submitted to your CDash dashboard during continuous integration processes.


## Required Configuration

### Environment Variables

Configure these secrets in your CI/CD environment for CDash submission:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `CTEST_DASHBOARD_SITE` | CDash server URL (e.g., `my.cdash.org`) | ✅ Required | None |
| `CTEST_DASHBOARD_LOCATION` | Submit endpoint (e.g., `/submit.php?project=MyProject`) | ✅ Required | None |
| `CDASH_AUTH_TOKEN` | Bearer token for authentication | Optional | None (no auth) |
| `CTEST_DASHBOARD_MODEL` | Dashboard model: `Experimental`, `Nightly`, `Experimental` | Optional | `Experimental` |
| `CTEST_DROP_METHOD` | Upload protocol | Optional | `https` |
| `CTEST_TEST_TIMEOUT_PRESET` | Test timeout in seconds | Optional | `300` |

## Setup Instructions

### GitHub Actions Setup

1. **Navigate to Repository Settings**
   ```
   Repository → Settings → Secrets and variables → Actions
   ```

2. **Add Required Secrets**
   - Add `CTEST_DASHBOARD_SITE` with your CDash server URL
   - Add `CTEST_DASHBOARD_LOCATION` with your project's submit path
   - Optionally add `CDASH_AUTH_TOKEN` for authenticated submissions

3. **Trigger Build**
   - Push code or create a pull request
   - Monitor the Actions tab for CDash submission status
