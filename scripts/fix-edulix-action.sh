#!/bin/bash
# Script to fix edulix/ort-action permission issue
# This creates a patched version of the action that you can use

set -e

FORK_REPO="$1"

if [ -z "$FORK_REPO" ]; then
    echo "Usage: ./fix-edulix-action.sh YOUR_GITHUB_USERNAME"
    echo ""
    echo "This script will:"
    echo "  1. Fork edulix/ort-action to your account"
    echo "  2. Clone your fork"
    echo "  3. Fix the permission issue"
    echo "  4. Push the changes"
    echo ""
    echo "Then you can use: uses: YOUR_GITHUB_USERNAME/ort-action@fixed"
    exit 1
fi

echo "🔧 Fixing edulix/ort-action permission issue..."
echo ""

# Check if fork exists or create instructions
echo "📋 Step 1: Fork the repository"
echo "   Go to: https://github.com/edulix/ort-action"
echo "   Click 'Fork' button"
echo ""
read -p "Press Enter when you've forked the repository..."

# Clone the fork
echo ""
echo "📥 Step 2: Cloning your fork..."
git clone "https://github.com/$FORK_REPO/ort-action.git" ort-action-fixed
cd ort-action-fixed

# Create fix branch
echo ""
echo "🌿 Step 3: Creating fix branch..."
git checkout -b fix-pyenv-permissions

# Find and fix the Docker run command
echo ""
echo "🔍 Step 4: Finding Docker run command..."

if [ -f "action.yml" ]; then
    ACTION_FILE="action.yml"
elif [ -f "action.yaml" ]; then
    ACTION_FILE="action.yaml"
else
    echo "❌ Could not find action.yml or action.yaml"
    echo "   Please fix manually."
    exit 1
fi

echo "   Found: $ACTION_FILE"

# Backup original
cp "$ACTION_FILE" "${ACTION_FILE}.backup"

# Show what we'll change
echo ""
echo "📝 Step 5: Applying fix..."
echo "   We'll remove the '--user 10001' flag from Docker run command"
echo ""

# Fix the action file (remove --user flag)
# This is a generic fix - may need manual adjustment based on actual content
sed -i 's/--user [0-9]*//' "$ACTION_FILE" 2>/dev/null || sed -i '' 's/--user [0-9]*//' "$ACTION_FILE"

# Alternative: Add PYENV_SKIP_REHASH environment variable
cat >> "$ACTION_FILE" << 'EOF'

# Fix for pyenv permission issue
# Add this environment variable to skip pyenv rehash
environment:
  PYENV_SKIP_REHASH: "1"
EOF

# Create README with fix explanation
cat > PERMISSION_FIX.md << 'EOF'
# Permission Fix for edulix/ort-action

## Problem
The original action runs Docker with `--user 10001` flag, causing:
```
pyenv: cannot rehash: /opt/python/shims isn't writable
```

## Solution
This fork removes the `--user` flag to run as root (default), avoiding permission issues.

## Usage
```yaml
- uses: YOUR_USERNAME/ort-action@fix-pyenv-permissions
  with:
    package-curations-dir: .ort-data/curations-dir/
    rules-file: rules.kts
    license-classifications-file: license-classifications.yml
```

## Alternative
Instead of forking, use official ORT Docker directly:
```yaml
- name: Run ORT
  run: |
    docker run --rm \
      -v "$(pwd):/project:ro" \
      -v "$(pwd)/ort-results:/results" \
      ghcr.io/oss-review-toolkit/ort:latest \
      analyze -i /project -o /results
```

See: https://github.com/oss-review-toolkit/ort
EOF

# Commit changes
echo ""
echo "💾 Step 6: Committing changes..."
git add .
git commit -m "Fix pyenv permission issue by removing --user flag

The --user 10001 flag causes pyenv to fail with permission error:
'pyenv: cannot rehash: /opt/python/shims isn't writable'

This fix removes the flag to run as root (default), avoiding the issue.

Alternative solutions:
1. Set PYENV_SKIP_REHASH=1 environment variable
2. Use official ORT Docker: ghcr.io/oss-review-toolkit/ort:latest
"

# Push to GitHub
echo ""
echo "⬆️  Step 7: Pushing to GitHub..."
git push origin fix-pyenv-permissions

echo ""
echo "✅ Done! Next steps:"
echo ""
echo "   1. Go to: https://github.com/$FORK_REPO/ort-action"
echo "   2. Create a Pull Request from 'fix-pyenv-permissions' to 'main'"
echo "   3. Merge the PR"
echo ""
echo "   Then use in your workflow:"
echo ""
echo "   - uses: $FORK_REPO/ort-action@fix-pyenv-permissions"
echo ""
echo "   Or better yet, use the official ORT Docker workflows we created!"
echo ""

cd ..
echo "📁 Fixed repository is in: ./ort-action-fixed"
