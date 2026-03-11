# =============================================================
# Dockerfile for n8n with pre-loaded workflow
# =============================================================
# WHAT THIS DOES:
# 1. Starts from the official n8n Docker image (has n8n pre-installed)
# 2. Copies your workflow JSON into a folder n8n watches on startup
# 3. Copies a custom entrypoint script that imports the workflow
# 4. Exposes port 5678 (n8n's default web interface port)
# =============================================================

# --- Stage 1: Use the official n8n image as our base ---
FROM n8nio/n8n:latest

# Set the user to root temporarily to create directories and copy files
USER root

# Create the directory where n8n will look for workflow files
RUN mkdir -p /home/node/.n8n/workflows

# Copy your exported workflow JSON into the container
# This is the "Auto Calendar.json" file from your repository
COPY workflows/ /home/node/.n8n/workflows/

# Copy the custom entrypoint script that handles workflow import
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /docker-entrypoint.sh

# Ensure the node user owns all n8n data files
RUN chown -R node:node /home/node/.n8n

# Switch back to the non-root "node" user for security
USER node

# Tell Docker that n8n listens on port 5678
EXPOSE 5678

# Use our custom entrypoint script instead of the default one
ENTRYPOINT ["/docker-entrypoint.sh"]