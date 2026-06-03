#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_PATH="$REPO_ROOT/docs"
HOSTING_BASE_PATH="CDMarkdownKit"

echo "Generating DocC documentation..."
swift package --disable-sandbox generate-documentation \
    --target CDMarkdownKit \
    --output-path "$OUTPUT_PATH" \
    --transform-for-static-hosting \
    --hosting-base-path "$HOSTING_BASE_PATH"

# GitHub Pages runs Jekyll by default, which can corrupt the binary LMDB
# index files DocC uses for search. This bypasses Jekyll entirely.
touch "$OUTPUT_PATH/.nojekyll"

# Redirect any unknown URLs to the documentation root rather than showing
# a bare GitHub 404. All valid pages have their own index.html (generated
# by --transform-for-static-hosting), so a true 404 means a bad URL.
cat > "$OUTPUT_PATH/404.html" <<'EOF'
<!doctype html>
<html lang="en-US">
<head>
  <meta charset="utf-8">
  <title>CDMarkdownKit Documentation</title>
  <script>window.location.replace('/CDMarkdownKit/documentation/cdmarkdownkit/');</script>
  <noscript><meta http-equiv="refresh" content="0;url=/CDMarkdownKit/documentation/cdmarkdownkit/"></noscript>
</head>
<body></body>
</html>
EOF

echo "Done. Output written to $OUTPUT_PATH"
