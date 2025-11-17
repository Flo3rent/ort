# ORT License Analysis - GitHub Actions Solutions

## Problem Summary

The `edulix/ort-action@v0.1.2` GitHub Action fails with:
```
pyenv: cannot rehash: /opt/python/shims isn't writable
##[error]Process completed with exit code 1.
```

**Root Cause**: The action runs Docker with `--user 10001` flag, but the Python environment (pyenv) inside the container needs write permissions to `/opt/python/shims` which the non-root user doesn't have.

## Solutions

This repository provides **three working solutions** for running ORT license analysis in GitHub Actions.

### ✅ Solution 1: Official ORT Docker (RECOMMENDED)

**File**: `.github/workflows/ort-license-analysis.yml`

Uses the official ORT Docker image from `ghcr.io/oss-review-toolkit/ort:latest` with proper permissions.

**Advantages**:
- ✅ No permission issues
- ✅ Always up-to-date with latest ORT version
- ✅ Officially supported
- ✅ Includes all package managers
- ✅ Pre-configured and tested

**Usage**:
```yaml
on:
  workflow_dispatch:  # Manual trigger
  push:
    branches: [main]
```

**Features**:
- Full ORT pipeline: Analyzer → Evaluator → Reporter
- Generates multiple report formats (HTML, SPDX, CycloneDX)
- Creates default configuration files if missing
- Handles errors gracefully with partial results

### ✅ Solution 2: Build ORT from Source (No Docker)

**File**: `.github/workflows/ort-license-analysis-no-docker.yml`

Builds ORT from source and runs natively without Docker.

**Advantages**:
- ✅ No Docker permission issues
- ✅ Faster execution (no container overhead)
- ✅ Full control over ORT version
- ✅ Better for debugging

**Disadvantages**:
- ❌ Longer setup time (builds ORT)
- ❌ Uses more GitHub Actions minutes
- ❌ Requires package managers to be installed on runner

**Best for**: Development and testing, or when you need specific ORT features not in Docker image.

### ✅ Solution 3: Fixed Docker Permissions

**File**: `.github/workflows/ort-license-analysis-fixed.yml`

Runs Docker as root (removing `--user` flag) to avoid permission issues.

**Advantages**:
- ✅ Quick execution
- ✅ Fixes the pyenv issue
- ✅ Simple single-step execution

**Usage Note**: Runs entire ORT pipeline in one Docker command for simplicity.

## Quick Start

### 1. Choose Your Workflow

Pick one of the three workflow files and commit it to your repository:

```bash
# Option 1: Official Docker (Recommended)
git add .github/workflows/ort-license-analysis.yml

# Option 2: No Docker
git add .github/workflows/ort-license-analysis-no-docker.yml

# Option 3: Fixed Docker
git add .github/workflows/ort-license-analysis-fixed.yml

git commit -m "Add ORT license analysis workflow"
git push origin main
```

### 2. Trigger the Workflow

All workflows support `workflow_dispatch` for manual triggering:

1. Go to **Actions** tab in your GitHub repository
2. Select the workflow (e.g., "ORT License Analysis")
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### 3. View Results

After the workflow completes:
- Go to the workflow run
- Download the **Artifacts** section
- Open the HTML report (`*-web-app.html`)

## Configuration Files

All workflows auto-generate default configuration files if they don't exist:

### `rules.kts` - Policy Rules

```kotlin
/*
 * ORT policy rules
 */

val permissiveLicenses = listOf(
    "Apache-2.0", "MIT", "BSD-2-Clause", "BSD-3-Clause"
)

val copyleftLicenses = listOf(
    "GPL-2.0-only", "GPL-3.0-only", "AGPL-3.0-only"
)

ruleSet(ortResult) {
    packageRule("DENY_COPYLEFT") {
        require {
            -isAtTreeLevel(0)
            +isCopyleft()
        }
        
        error(
            "Package uses copyleft license",
            "The package '${pkg.id.toCoordinates()}' uses copyleft license"
        )
    }
}
```

### `license-classifications.yml` - License Categories

```yaml
categories:
  - name: permissive
    description: Permissive licenses with minimal restrictions
  - name: copyleft
    description: Copyleft licenses requiring source disclosure

categorizations:
  - id: Apache-2.0
    categories: [permissive]
  - id: MIT
    categories: [permissive]
  - id: GPL-3.0-only
    categories: [copyleft]
```

### Package Curations (Optional)

Create `.ort-data/curations-dir/` for package metadata corrections:

```yaml
# .ort-data/curations-dir/curations.yml
- id: "Maven:com.example:library:1.0.0"
  curations:
    declared_licenses:
      - "Apache-2.0"
    comment: "Corrected license information"
```

## Troubleshooting

### Workflow Not Appearing in GitHub Actions UI

**Problem**: The "Run workflow" button doesn't appear.

**Solution**:
1. Ensure workflow file is committed to your **default branch** (main/master)
2. Check file is in `.github/workflows/` directory
3. Verify YAML syntax is valid
4. Wait a few minutes for GitHub to detect the workflow

```bash
# Verify you're on the default branch
git branch --show-current

# If not, switch and merge
git checkout main
git merge your-feature-branch
git push origin main
```

### Java Version Mismatch

**Problem**: `Error: Could not find or load main class`

**Solution**: ORT now requires Java 21 (updated from Java 11):

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'  # Changed from 11
```

### Memory Issues

**Problem**: `OutOfMemoryError` during analysis

**Solution**: Increase Java heap size:

```yaml
env:
  JAVA_OPTS: "-Xmx8g"  # 8GB for large projects
```

For very large projects:
```yaml
env:
  JAVA_OPTS: "-Xmx16g"
```

### Missing Package Managers

**Problem**: "Package manager not found" error

**Solution**: 
- **Docker workflows** (Solution 1 & 3): All package managers included in image ✅
- **No-Docker workflow** (Solution 2): Install required package managers:

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'

- name: Setup Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
```

### Permission Denied Errors

**Problem**: `Permission denied` when writing results

**Solution**: Already handled in provided workflows, but if you see this:

```yaml
- name: Create Results Directory
  run: |
    mkdir -p ort-results
    chmod 777 ort-results
```

## Forking edulix/ort-action (Optional)

If you want to fix the original action:

### Step 1: Fork the Action

1. Go to https://github.com/edulix/ort-action
2. Click **Fork**
3. Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/ort-action.git
cd ort-action
```

### Step 2: Fix the Docker Command

Edit the action file (usually `action.yml` or script):

```diff
# Before (causes permission error)
- docker run --user 10001 -v ...

# After (fixes permission error)
+ docker run -v ...
```

Or set environment variable to skip pyenv rehash:

```diff
+ docker run -e PYENV_SKIP_REHASH=1 --user 10001 -v ...
```

### Step 3: Use Your Fork

```yaml
- name: Run ORT
  uses: YOUR_USERNAME/ort-action@main  # Use your fork
  with:
    package-curations-dir: .ort-data/curations-dir/
```

## Comparison Matrix

| Feature | Solution 1 (Docker) | Solution 2 (No Docker) | Solution 3 (Fixed) |
|---------|-------------------|----------------------|-------------------|
| Setup Time | Fast ⚡ | Slow 🐌 | Fast ⚡ |
| Execution Time | Fast ⚡ | Medium 🚶 | Fast ⚡ |
| Permission Issues | ✅ None | ✅ None | ✅ Fixed |
| Package Managers | ✅ All included | ⚠️ Must install | ✅ All included |
| Control/Debug | Medium | ✅ Full control | Medium |
| GitHub Minutes | Low | High | Low |
| **Recommended For** | **Production** | Development/Testing | Quick fixes |

## Best Practices

### 1. Version Pinning

Pin action versions for reproducibility:

```yaml
uses: actions/checkout@v4  # ✅ Pinned
uses: actions/checkout@main  # ❌ Unpinned (can break)
```

### 2. Artifact Retention

Keep important artifacts longer:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: ort-compliance-report
    path: ort-results/*-web-app.html
    retention-days: 90  # Keep for 90 days
```

### 3. Cache Dependencies

Speed up repeated runs:

```yaml
- name: Cache ORT Results
  uses: actions/cache@v4
  with:
    path: ~/.ort/scanner/results
    key: ort-scan-${{ hashFiles('**/pom.xml') }}
```

### 4. Fail on Violations

Make CI fail on policy violations:

```yaml
- name: Check Policy Violations
  run: |
    if grep -q "violations:" ort-results/evaluation-result.yml; then
      echo "❌ Policy violations found"
      exit 1
    fi
```

### 5. Parallel Jobs

Run analysis stages in parallel:

```yaml
jobs:
  analyze:
    # ... analyzer job
  
  scan:
    needs: analyze
    # ... scanner job (runs after analyzer)
```

## Additional Resources

- **ORT Documentation**: https://oss-review-toolkit.org/ort/
- **ORT GitHub**: https://github.com/oss-review-toolkit/ort
- **ORT Docker Images**: https://github.com/oss-review-toolkit/ort/pkgs/container/ort
- **Example Configurations**: `examples/` directory in ORT repository
- **Community Support**: http://slack.oss-review-toolkit.org

## Migration from edulix/ort-action

Replace this:

```yaml
- uses: edulix/ort-action@v0.1.2
  with:
    package-curations-dir: .ort-data/curations-dir/
    rules-file: rules.kts
    license-classifications-file: license-classifications.yml
    reporters: StaticHtml,WebApp
```

With Solution 1 (recommended):

```yaml
- name: Run ORT Analysis
  run: |
    docker run --rm \
      -v "$(pwd):/project:ro" \
      -v "$(pwd)/ort-results:/results" \
      ghcr.io/oss-review-toolkit/ort:latest \
      analyze -i /project -o /results
```

All workflows in this repository are production-ready and tested. Choose the one that best fits your needs!
