# ORT GitHub Actions - Quick Start

## ⚡ 3-Step Setup

### Step 1: Choose a Workflow

```bash
# Recommended: Official Docker
cp .github/workflows/ort-license-analysis.yml .github/workflows/

# Alternative: No Docker
cp .github/workflows/ort-license-analysis-no-docker.yml .github/workflows/

# Alternative: Fixed Docker
cp .github/workflows/ort-license-analysis-fixed.yml .github/workflows/
```

### Step 2: Commit & Push

```bash
git add .github/workflows/ort-license-analysis.yml
git commit -m "Add ORT license analysis"
git push origin main
```

### Step 3: Run

1. Go to **Actions** tab
2. Select **ORT License Analysis**
3. Click **Run workflow**

## 🔧 Quick Fixes

### Fix #1: pyenv Permission Error

**Error**: `pyenv: cannot rehash: /opt/python/shims isn't writable`

**Solution**: Remove `--user` flag from Docker run:

```yaml
# ❌ Wrong (edulix/ort-action does this)
docker run --user 10001 -v $(pwd):/project edulix/ort:latest

# ✅ Correct
docker run -v $(pwd):/project ghcr.io/oss-review-toolkit/ort:latest
```

### Fix #2: Workflow Not Appearing

**Problem**: "Run workflow" button missing

**Solution**: Workflow must be on **default branch** (main/master):

```bash
git checkout main
git merge your-feature-branch
git push origin main
```

### Fix #3: Java Version Error

**Error**: `Could not find or load main class`

**Solution**: Update Java version to 21:

```yaml
- uses: actions/setup-java@v4
  with:
    java-version: '21'  # Was 11, now 21
```

### Fix #4: Out of Memory

**Error**: `java.lang.OutOfMemoryError`

**Solution**: Increase heap size:

```yaml
env:
  JAVA_OPTS: "-Xmx8g"  # 8GB (or -Xmx16g for large projects)
```

## 📋 File Structure

```
your-repo/
├── .github/
│   └── workflows/
│       └── ort-license-analysis.yml
├── .ort-data/
│   └── curations-dir/
│       └── curations.yml (optional)
├── rules.kts (auto-generated if missing)
├── license-classifications.yml (auto-generated if missing)
└── ort-results/ (created by workflow)
```

## 🎯 Minimal Working Example

```yaml
name: ORT Analysis

on:
  workflow_dispatch:

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run ORT
        run: |
          mkdir -p ort-results
          docker run --rm \
            -v "$(pwd):/project:ro" \
            -v "$(pwd)/ort-results:/results" \
            ghcr.io/oss-review-toolkit/ort:latest \
            analyze -i /project -o /results
      
      - uses: actions/upload-artifact@v4
        with:
          name: results
          path: ort-results/
```

## 🆚 Which Workflow Should I Use?

| Use Case | Workflow |
|----------|----------|
| Production deployment | `ort-license-analysis.yml` ⭐ |
| Development/debugging | `ort-license-analysis-no-docker.yml` |
| Quick fix for edulix action | `ort-license-analysis-fixed.yml` |
| Minimal setup | Copy minimal example above |

## 📊 Report Outputs

After workflow completes, download artifacts:

- `*-web-app.html` - Interactive HTML report (open in browser)
- `*-static-html-report.html` - Static HTML report
- `bom.spdx.json` - SPDX SBOM
- `bom.cyclonedx.json` - CycloneDX SBOM
- `evaluation-result.yml` - Raw results

## 🐛 Still Having Issues?

Check the comprehensive guide: [GITHUB_ACTIONS_ORT_GUIDE.md](./GITHUB_ACTIONS_ORT_GUIDE.md)

Or ask for help:
- **ORT Slack**: http://slack.oss-review-toolkit.org
- **ORT GitHub Issues**: https://github.com/oss-review-toolkit/ort/issues

## 🎓 Next Steps

1. ✅ Customize `rules.kts` for your policy requirements
2. ✅ Add package curations in `.ort-data/curations-dir/`
3. ✅ Configure scanning (add scanner stage)
4. ✅ Set up automatic triggers (on push, pull_request)
5. ✅ Integrate with PR checks (fail on violations)

---

**Need more details?** See the full guide: [GITHUB_ACTIONS_ORT_GUIDE.md](./GITHUB_ACTIONS_ORT_GUIDE.md)
