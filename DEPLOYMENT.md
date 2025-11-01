# Deployment Guide

## GitHub Pages Deployment

This project uses GitHub Actions to automatically build and deploy the Godot game to GitHub Pages.

### How It Works

1. **Build Process**: 
   - The workflow checks out the repository with Git LFS enabled (needed for large assets like `room.glb`)
   - Godot Engine exports the game for web (HTML5/WebAssembly)
   - Build artifacts are created in `build/web/` including:
     - `index.html` - Main HTML file
     - `index.js` - JavaScript loader
     - `index.wasm` - WebAssembly binary
     - `index.pck` - Game data package

2. **Deployment Process**:
   - The build artifacts are deployed directly to the `gh-pages` branch
   - **Important**: Binary files (.wasm, .pck) are committed as regular Git files, NOT using Git LFS
   - This is critical because GitHub Pages does not serve Git LFS files correctly

### Why Not Use LFS for Deployment?

GitHub Pages serves Git LFS pointer files instead of the actual binary content. This causes the browser to receive text pointer files instead of WebAssembly binaries, resulting in errors like:

```
Uncaught (in promise) CompileError: wasm validation error: at offset 4: failed to match magic number
```

By committing the build artifacts as regular Git files, GitHub Pages serves the actual binary content correctly.

### Triggering a Deployment

The workflow runs automatically on every push to the repository. The game will be available at:
`https://iamsteini.github.io/typing/`

### Troubleshooting

If you see WASM validation errors:
1. Check that the `gh-pages` branch does not have `.gitattributes` configuring LFS for `.wasm` or `.pck` files
2. Verify that the deployment step in `.github/workflows/godot.yml` does not use `git lfs install`
3. Force a new deployment by pushing a new commit
