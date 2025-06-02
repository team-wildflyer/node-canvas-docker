FROM node:22.16.0

LABEL maintainer="daan@wildflyer.co"
LABEL description="Custom Node.js base image with prebuilt native modules"
LABEL version="1.0.0"

# Install system dependencies for canvas and other native modules
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    build-essential \
    g++ \
    make \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    libfontconfig1-dev \
    fontconfig \
    fonts-freefont-ttf \
    fonts-liberation \
    git \
    ca-certificates \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install global packages
RUN npm install -g pnpm@10.2.1 turbo npm-check-updates

# Create cache directories
RUN mkdir -p /opt/prebuilt-modules /opt/module-cache

# Pre-install and build common native modules
WORKDIR /tmp/prebuilt

# Create package.json with common native modules
RUN echo '{ \
  "name": "prebuilt-modules", \
  "version": "1.0.0", \
  "dependencies": { \
    "canvas": "3.1.0", \
    "sharp": "^0.33.0", \
    "bcrypt": "^5.1.0", \
    "sqlite3": "^5.1.0", \
    "node-gyp": "^10.0.0", \
    "@mapbox/node-pre-gyp": "^1.0.0" \
  } \
}' > package.json

# Install and build native modules
RUN pnpm install --no-frozen-lockfile

# Rebuild each native module to ensure proper compilation
RUN cd node_modules/canvas && npm rebuild --build-from-source
RUN cd node_modules/sharp && npm rebuild --build-from-source || true
RUN cd node_modules/bcrypt && npm rebuild --build-from-source || true
RUN cd node_modules/sqlite3 && npm rebuild --build-from-source || true

# Verify canvas was built properly
RUN cd node_modules/canvas && \
    echo "Canvas build contents:" && \
    find . -name "*.node" -o -name "build" -type d | head -10 && \
    node -e "console.log('Canvas test:', require('./index.js').createCanvas ? 'OK' : 'FAILED')"

# Copy built modules to cache directory
RUN cp -r node_modules /opt/prebuilt-modules/
RUN cp package.json /opt/prebuilt-modules/

# Create module info file using a different approach to avoid shell escaping issues
RUN cd node_modules && \
    echo "# Prebuilt Native Modules" > /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "Canvas: $(node -pe "require('./canvas/package.json').version")" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "Sharp: $(node -pe "require('./sharp/package.json').version")" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "Bcrypt: $(node -pe "require('./bcrypt/package.json').version")" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "SQLite3: $(node -pe "require('./sqlite3/package.json').version")" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "Built on: $(date)" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "Node version: $(node --version)" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "NPM version: $(npm --version)" >> /opt/prebuilt-modules/MODULE_INFO.md && \
    echo "PNPM version: $(pnpm --version)" >> /opt/prebuilt-modules/MODULE_INFO.md

# Clean up build directory
WORKDIR /
RUN rm -rf /tmp/prebuilt

# Set working directory for applications
WORKDIR /app

# Add helper script for checking prebuilt modules
RUN echo '#!/bin/bash\n\
echo "=== Prebuilt Native Modules Info ==="\n\
cat /opt/prebuilt-modules/MODULE_INFO.md\n\
echo "\n=== Available Modules ==="\n\
ls -la /opt/prebuilt-modules/node_modules/\n\
' > /usr/local/bin/show-prebuilt-modules && chmod +x /usr/local/bin/show-prebuilt-modules

# Verify installations
RUN node --version && npm --version && pnpm --version && turbo --version