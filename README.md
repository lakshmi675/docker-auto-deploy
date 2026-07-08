# 🚀 Docker Auto Deploy

A full-stack demo project showing a self-validating, auto-deploying, auto-rolling-back
Docker setup.

- **React** frontend (Vite, hot reload)
- **Node.js / Express** backend (nodemon, hot reload)
- **MongoDB** database
- **Docker Compose** to run everything together
- **ESLint** on both frontend and backend
- **Validation script** (lint + build check) that must pass before any deploy
- **Auto Deploy script** that builds & ships a new version only if validation passes
- **Rollback script** that automatically restores the last known-good version if
  the new one fails its health check
- **Health checks** on both backend and frontend

## Project structure

```
docker-auto-deploy/
├── frontend/         React app (Vite)
├── backend/          Express API + MongoDB models
├── database/         Mongo seed script
├── scripts/          validate.sh, deploy.sh, rollback.sh, watch.sh, health-check.sh
├── docker-compose.yml
├── .env
└── README.md
```

## Requirements

- Docker & Docker Compose v2 (`docker compose version`)
- That's it — Node.js does **not** need to be installed on your host. The
  validation script runs lint/build checks inside a throwaway `node:20-alpine`
  container.

## 1. First-time setup

```bash
cd docker-auto-deploy
cp .env.example .env   # already provided with sane defaults, edit if needed
```

## 2. Run the stack

```bash
docker compose up
```

Then open:

- Frontend: http://localhost:5173
- Backend health: http://localhost:5000/api/health
- Backend data: http://localhost:5000/api/data

The frontend polls the backend every 5 seconds and shows live health status
and sample MongoDB items (seeded automatically on first run).

Both frontend and backend containers bind-mount your local `frontend/` and
`backend/` folders and run `vite` / `nodemon` inside the container, so any
code change you save on your machine is **hot-reloaded instantly** without
rebuilding the image.

## 3. Run validation manually

```bash
./scripts/validate.sh
```

This runs, in throwaway containers:

1. Backend `npm install` + `eslint`
2. Backend syntax check (`node --check`)
3. Frontend `npm install` + `eslint`
4. Frontend `npm install` + `vite build`

Exit code `0` = all good, non-zero = something failed.

## 4. Auto deploy

```bash
./scripts/deploy.sh
```

What it does, step by step:

1. **Validates** the code (calls `validate.sh`). If validation fails, the
   script stops immediately and **the currently running containers are left
   completely untouched** — nothing is rebuilt or restarted.
2. If validation passes, it **snapshots the current images** by tagging them
   `:previous` (so we always have a known-good fallback).
3. **Builds new images** with `docker compose build` and starts them with
   `docker compose up -d`.
4. **Health-checks** the new backend at `/api/health` for up to 30 seconds.
   - ✅ If healthy → deployment is complete, new version is live.
   - ❌ If unhealthy → `rollback.sh` is triggered automatically.

## 5. Rollback

```bash
./scripts/rollback.sh
```

Restores the `:previous` tagged images (the last version that was healthy),
restarts the containers, and health-checks them again. This runs
automatically from inside `deploy.sh` if a new deployment fails its health
check, but you can also run it manually any time.

## 6. Fully automatic mode (watch + deploy on save)

```bash
./scripts/watch.sh
```

This watches `frontend/src` and `backend/src` for changes and automatically
runs `validate → deploy → (rollback if unhealthy)` every time you save a
file — no need to run `deploy.sh` by hand.

## Demo: proving the safety net works

**A. Successful deploy**

1. Edit `frontend/src/App.jsx`, change the tagline text, save.
2. Run `./scripts/deploy.sh` (or let `watch.sh` trigger it).
3. Validation passes → new containers build and start → health check passes
   → refresh http://localhost:5173 and see your change live.

**B. Blocked deploy (validation fails)**

1. Break the code on purpose, e.g. in `backend/server.js` add a stray
   character like `const x = ;`.
2. Run `./scripts/deploy.sh`.
3. Validation fails (syntax check / build catches it) → the script exits
   with an error and **prints that the old containers are untouched** —
   your app at http://localhost:5173 keeps working exactly as before.

**C. Automatic rollback (deploy succeeds validation but breaks at runtime)**

1. Change `backend/src/db.js` to point `MONGO_URI` at a host that doesn't
   exist, so the backend can start but never reports healthy.
2. Run `./scripts/deploy.sh`.
3. Validation passes (it's valid JS) → new images build and start → health
   check fails after ~30 seconds → `rollback.sh` runs automatically →
   previous working images are restored and health-checked again.

## Useful commands

```bash
docker compose ps                 # see running containers
docker compose logs -f backend    # tail backend logs
docker compose logs -f frontend   # tail frontend logs
docker compose down               # stop everything
docker compose down -v            # stop and wipe the Mongo volume
docker images | grep docker-auto-deploy   # see current vs previous image tags
```

## Notes

- Image tags: each service is built as `docker-auto-deploy-<service>:current`.
  Before every deploy, `current` is snapshotted to `:previous`, which is what
  `rollback.sh` restores from.
- The dev Dockerfiles run `vite`/`nodemon` directly for hot reload during
  development. For a true production build you'd add a separate multi-stage
  Dockerfile that runs `npm run build` and serves static files (e.g. via
  nginx) — this project focuses on the dev/hot-reload + auto-deploy pipeline.
