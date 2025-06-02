# Custom Node.js Base Image

A custom Docker base image with Node.js and prebuilt native modules for faster container builds.

## Features

- **Node.js 22.16.0** with npm, pnpm, and turbo pre-installed
- **Prebuilt native modules**: canvas, sharp, bcrypt, sqlite3
- **System dependencies** for common native Node.js modules
- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Automated builds** with GitHub Actions
- **Security scanning** with Trivy
- **Scaleway Container Registry** integration

## Prebuilt Modules

This image includes the following native modules prebuilt and ready to use:

| Module | Version | Purpose |
|--------|---------|---------|
| canvas | 3.1.0 | 2D graphics and image manipulation |
| sharp | ^0.33.0 | High-performance image processing |
| bcrypt | ^5.1.0 | Password hashing |
| sqlite3 | ^5.1.0 | SQLite database driver |

## Usage

### In Your Dockerfile

```dockerfile
FROM rg.fr-par.scw.cloud/your-namespace/node-base:latest

WORKDIR /app

# Copy your application files
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Install dependencies (native modules will be much faster)
RUN pnpm install --frozen-lockfile

# Copy the rest of your application
COPY . .

# Build your application
RUN pnpm run build

CMD ["pnpm", "start"]
```

### Optimized Usage with Prebuilt Modules

```dockerfile
FROM rg.fr-par.scw.cloud/your-namespace/node-base:latest

WORKDIR /app

COPY package*.json ./

# Copy prebuilt modules for matching versions
RUN if grep -q "canvas.*3.1.0" package.json; then \
      mkdir -p node_modules && \
      cp -r /opt/prebuilt-modules/node_modules/canvas node_modules/; \
    fi

RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

CMD ["pnpm", "start"]
```

## Available Tags

- `latest` - Latest stable build from main branch
- `v1.0.0` - Specific version tags
- `main` - Latest from main branch
- `develop` - Latest from develop branch

## Building Locally

```bash
# Clone the repository
git clone <your-repo-url>
cd node-base-image

# Build the image
docker build -t node-base:local .

# Test the image
docker run --rm node-base:local show-prebuilt-modules
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| NODE_VERSION | 22.16.0 | Node.js version to use |

## Helper Commands

The image includes helpful commands:

```bash
# Show information about prebuilt modules
docker run --rm your-image show-prebuilt-modules

# Check Node.js installation
docker run --rm your-image node --version
```

## GitHub Actions Setup

### Required Secrets

Add these secrets to your GitHub repository:

1. **SCALEWAY_SECRET_KEY**: Your Scaleway API secret key
   - Go to Settings → Secrets and variables → Actions
   - Add `SCALEWAY_SECRET_KEY` with your Scaleway secret key

### Workflow Triggers

The build workflow runs on:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Version tags (v*)
- Weekly schedule (Sundays at 2 AM UTC)
- Manual dispatch with custom parameters

## Scaleway Container Registry Setup

1. Create a namespace in Scaleway Container Registry
2. Update the `IMAGE_NAME` in `.github/workflows/build-and-deploy.yml`:
   ```yaml
   env:
     IMAGE_NAME: your-namespace/node-base
   ```
3. Generate a secret key with Container Registry permissions
4. Add the secret key to GitHub repository secrets

## Development

### Adding New Native Modules

To add more prebuilt native modules:

1. Edit the `Dockerfile`
2. Add the module to the `package.json` in the prebuilt section:
   ```dockerfile
   RUN echo '{ \
     "dependencies": { \
       "canvas": "3.1.0", \
       "sharp": "^0.33.0", \
       "your-new-module": "^1.0.0" \
     } \
   }' > package.json
   ```
3. Add the rebuild step:
   ```dockerfile
   RUN cd node_modules/your-new-module && npm rebuild --build-from-source || true
   ```

### Testing Changes

```bash
# Build locally
docker build -t node-base:test .

# Test the modules
docker run --rm node-base:test show-prebuilt-modules

# Test specific module
docker run --rm node-base:test node -e "require('/opt/prebuilt-modules/node_modules/canvas')"
```

## Troubleshooting

### Common Issues

1. **Module not found**: Ensure the module is properly prebuilt and copied
2. **Architecture mismatch**: Use `--platform linux/amd64` when building on ARM for x86 deployment
3. **Permission errors**: Check Scaleway registry permissions and secret key

### Debug Commands

```bash
# List prebuilt modules
docker run --rm your-image ls -la /opt/prebuilt-modules/node_modules/

# Check module info
docker run --rm your-image cat /opt/prebuilt-modules/MODULE_INFO.md

# Interactive debugging
docker run -it your-image bash
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## Changelog

### v1.0.0
- Initial release with Node.js 22.16.0
- Prebuilt canvas, sharp, bcrypt, sqlite3 modules
- Multi-architecture support
- Automated CI/CD pipeline