#!/bin/sh
# Streamlined launcher for Bloom Nix Installer

# Set environment variables for project structure
export BLOOM_PROJECT_ROOT="${BLOOM_PROJECT_ROOT:-$(realpath ../../.)}"
export BLOOM_MODULE_BASE="${BLOOM_MODULE_BASE:-$(realpath ../base)}"
export BLOOM_MODULE_DESKTOP="${BLOOM_MODULE_DESKTOP:-$(realpath ../desktop)}"
export BLOOM_MODULE_HARDWARE="${BLOOM_MODULE_HARDWARE:-$(realpath ../hardware)}"
export BLOOM_MODULE_PACKAGES="${BLOOM_MODULE_PACKAGES:-$(realpath ../packages)}"
export BLOOM_MODULE_BRANDING="${BLOOM_MODULE_BRANDING:-$(realpath ../branding)}"
export BLOOM_HOST_CONFIG="${BLOOM_HOST_CONFIG:-$(realpath ../../hosts/desktop)}"
export BLOOM_ENABLE_PLASMA6="true"

# Check if installer is already running
if [ -f /tmp/bloom-installer-running ]; then
  echo "Installer is already running."
  # Use xdg-open instead of directly launching firefox for better desktop compatibility
  xdg-open http://localhost:8501
  exit 0
fi

# Create marker file
touch /tmp/bloom-installer-running

# Start Streamlit without browser auto-opening (this is more reliable)
streamlit run /etc/bloom-installer/bloom-installer-minimal.py \
  --server.port 8501 \
  --server.headless true \
  --server.enableCORS false \
  --server.enableXsrfProtection false \
  --server.maxUploadSize 10 \
  > /tmp/streamlit.log 2>&1 &

# Store PID
echo $! > /tmp/streamlit.pid

# Wait for server to start (check if port 8501 is listening)
echo "Starting Bloom Nix installer..."
attempts=0
max_attempts=30
while [ $attempts -lt $max_attempts ]; do
  sleep 0.5
  if nc -z localhost 8501; then
    break
  fi
  attempts=$((attempts + 1))
  echo -n "."
done

# Make sure server started
if ! nc -z localhost 8501; then
  echo "Failed to start installer. Check /tmp/streamlit.log for details."
  exit 1
fi

echo "Installer is ready!"

# Launch browser explicitly with a delay
sleep 1
xdg-utils http://localhost:8501

# Keep script running to maintain child process
wait
