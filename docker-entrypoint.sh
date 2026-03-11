#!/bin/sh
# =============================================================
# Custom Docker Entrypoint for n8n
# =============================================================
# WHAT THIS DOES:
# 1. Starts n8n in the background
# 2. Waits for n8n to be fully ready (health check)
# 3. Imports all workflow JSON files from /home/node/.n8n/workflows/
# 4. Keeps n8n running in the foreground
# =============================================================

set -e

echo "============================================="
echo "  n8n Calendar Automation - Starting Up"
echo "============================================="

# --- Start n8n in the background ---
# We start it in the background first so we can import workflows
# after the API is ready
echo "[1/4] Starting n8n in the background..."
n8n start &

# Save the process ID so we can bring it back to the foreground later
N8N_PID=$!

# --- Wait for n8n to be ready ---
# n8n needs a few seconds to initialize its database and API
echo "[2/4] Waiting for n8n to be ready..."
RETRIES=30
until wget -qO- http://localhost:5678/healthz > /dev/null 2>&1; do
  RETRIES=$((RETRIES - 1))
  if [ "$RETRIES" -le 0 ]; then
    echo "  ⚠️  n8n did not become ready in time. Workflows may need manual import."
    break
  fi
  echo "  Waiting... (${RETRIES} attempts remaining)"
  sleep 2
done
echo "  ✅ n8n is ready!"

# --- Import workflow JSON files (only on first run) ---
# Check if workflows have already been imported by looking for a marker file.
# This prevents re-importing on every restart, which would overwrite
# credential assignments made in the n8n UI.
IMPORT_MARKER="/home/node/.n8n/.workflows_imported"
echo "[3/4] Checking if workflows need to be imported..."
if [ ! -f "$IMPORT_MARKER" ]; then
  WORKFLOW_DIR="/home/node/.n8n/workflows"
  if [ -d "$WORKFLOW_DIR" ] && [ "$(ls -A $WORKFLOW_DIR/*.json 2>/dev/null)" ]; then
    for workflow_file in "$WORKFLOW_DIR"/*.json; do
      filename=$(basename "$workflow_file")
      echo "  📂 Importing: $filename"
      n8n import:workflow --input="$workflow_file" || echo "  ⚠️  Failed to import $filename"
    done
    # Create marker file so we don't re-import on next restart
    touch "$IMPORT_MARKER"
    echo "  ✅ All workflows imported!"
  else
    echo "  ℹ️  No workflow files found in $WORKFLOW_DIR"
  fi
else
  echo "  ✅ Workflows already imported (skipping to preserve credentials)"
fi

# --- Keep n8n running in the foreground ---
# The 'wait' command makes this script wait for n8n to finish
# This keeps the Docker container running
echo "[4/4] n8n is running on port 5678"
echo "============================================="
wait $N8N_PID