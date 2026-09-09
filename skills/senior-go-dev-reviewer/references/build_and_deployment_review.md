# Build and Deployment Review

Read this when a Go change under review touches build configuration, container definitions, deployment manifests, or the CI pipeline.

Do not raise findings here about infrastructure the diff does not touch; when the repository has no such configuration in scope, say so once and move on.

Check for:

- Reproducible builds
- Static linking when appropriate
- Minimal container images
- Non-root containers
- SBOM generation
- Signed artifacts
- Lint and test failing the pipeline on violation
