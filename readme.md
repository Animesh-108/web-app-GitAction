# web-app-GitAction

A minimal Node.js HTTP service used as a reference implementation of a tested, containerized GitHub Actions pipeline. The application is deliberately small so that the CI/CD configuration — not the business logic — is the subject of the repository.

![CI](https://github.com/Animesh-108/web-app-GitAction/actions/workflows/docker-build.yml/badge.svg)

---

## What this demonstrates

- **A test gate that actually gates.** The `build-and-push` job declares `needs: test`, so no image is published unless the Jest suite passes first.
- **Multi-stage Docker builds.** Dependencies are installed in a `node:18` builder stage; the runtime image is `node:18-alpine` carrying production-only dependencies and a single copied source file. Build tooling never reaches the published image.
- **Least-privilege workflow tokens.** The publishing job requests only `contents: read` and `packages: write`, and authenticates to GitHub Container Registry with the ephemeral `GITHUB_TOKEN` rather than a long-lived personal access token.

---

## Pipeline

```
push ──▶ test job                    build-and-push job
         ├─ checkout                 ├─ checkout
         ├─ setup-node 18            ├─ login → ghcr.io
         ├─ npm install              ├─ docker build (multi-stage)
         └─ npm test (jest)          └─ docker push :latest
              │                            ▲
              └──────── needs: test ───────┘
```

A failing test short-circuits the workflow; the registry is never touched.

---

## The application

`server.js` exports a bare `http.Server` that answers every request with `200 Hello DevOps!` in `text/plain`. It exports the server rather than calling `listen()` at import time, which is what makes it importable from the test file without binding a port.

`server.test.js` asserts the export is an `http.Server` instance, then closes it so Jest can exit cleanly.

---

## Running locally

```bash
npm install
npm test                 # jest, --forceExit
node -e "require('./server').listen(8080)"
curl localhost:8080      # → Hello DevOps!
```

## Running the container

```bash
docker build -t web-app-gitaction .
docker run --rm -p 8080:8080 web-app-gitaction
curl localhost:8080
```

The image listens on port **8080** (`EXPOSE 8080`, `CMD ["node", "server.js"]`).

## Pulling the published image

```bash
docker pull ghcr.io/animesh-108/my-first-image:latest
```

The workflow lowercases the repository owner before tagging, because GHCR rejects uppercase characters in image paths.

---

## Repository layout

```
.
├── .github/workflows/
│   └── docker-build.yml    # test → build → push to GHCR
├── Dockerfile              # multi-stage: node:18 builder → node:18-alpine runtime
├── server.js               # exports an http.Server (does not listen on import)
├── server.test.js          # jest: asserts the export is an http.Server
└── package.json            # test script: npx jest --forceExit
```

---

## Known issues

- **The workflow does not currently fire.** `docker-build.yml` triggers on `push` to `master`, but this repository's default branch is `main`, so pushes match no trigger. Fix by changing the branch filter to `[ "main" ]`.
- **`package.json` metadata points at a different repository** (`Anime1102/my-first-devops-project`) in its `repository`, `bugs`, and `homepage` fields.
- The image is published only as `:latest`, so deployments cannot be pinned to an immutable tag. Tagging with `${{ github.sha }}` alongside `latest` would make rollbacks possible.

---

## Tech stack

Node.js 18 · Jest · Docker (multi-stage) · GitHub Actions · GitHub Container Registry
