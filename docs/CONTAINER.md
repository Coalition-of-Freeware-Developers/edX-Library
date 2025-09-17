# Containerized build, test, and local CI

This repo includes a Dev Container and Docker Compose setup so you can build, test, and run GitHub workflows locally.

## Prerequisites

- Docker installed and running
- (Optional) VS Code with Dev Containers extension for a full IDE inside the container

## Open in Dev Container (recommended)

1. Open the repo folder in VS Code
2. When prompted, reopen in container. Alternatively, use the Command Palette: “Dev Containers: Reopen in Container”.
3. The container image installs CMake, Ninja, compilers, Python, and `act` (for local CI).

## Build and test inside the container

- One-shot build/test using Compose:

```powershell
# Build the image (first time or when Dockerfile changes)
docker compose build edx-dev

# Run the build+test job
docker compose run --rm edx-build
```

- Interactive dev shell:

```powershell
docker compose up -d edx-dev
# Then attach a shell
docker exec -it edx-library-dev bash
# From inside the container:
./scripts/ci-build.sh
```

Artifacts from builds end up under `build-ci/` in the repo root.

## Running GitHub workflows locally (act)

The container has `act` installed so you can run workflows locally.

Examples:

```bash
# From inside the container shell
scripts/ci-run-workflow.sh -w .github/workflows/ci.yml -e pull_request
scripts/ci-run-workflow.sh -w .github/workflows/linux.yml -j build-linux
```

You can provide secrets via `.act.secrets` (referenced from `.actrc`). Create it if needed:

```dotenv
MY_SECRET=foo
```

If you need the optional XPSceneryLib during local builds/tests, set:

```bash
export EDX_USE_FETCHCONTENT_XPLIB=ON
```

## Notes

- The repository’s CMake expects out-of-source builds. The helper script uses `build-ci/`.
- `EDX_CI_MODE=ON` is set in the container to emulate CI behavior.
- If Windows-specific steps are required, prefer running Linux/macOS workflows in the container; Windows workflows generally require Windows hosts and are not supported by Docker.

## Troubleshooting

- If vcpkg downloads are slow, ensure network access from the container and consider enabling Docker BuildKit cache mounts.
- If `act` fails due to missing runner images, it will pull defaults automatically. You can customize via `.actrc`.
- Ensure the Docker daemon socket is mounted; the devcontainer and compose files mount `/var/run/docker.sock`.
