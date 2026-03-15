# Curtail — Learning Notes

Notes and concepts picked up while building a type-safe URL shortener in **Haskell** with a **Gleam/BEAM** background worker.

## Stack

| Layer | Tech | Role |
|-------|------|------|
| API server | Haskell (Servant + Warp) | Type-safe HTTP routes, redirect handling |
| Database | SQLite via Persistent | Schema, migrations, connection pooling |
| Background worker | Gleam (OTP actor) | Expired link cleanup on a timer |

## How to build these docs

```bash
pip install mkdocs mkdocs-material
mkdocs serve        # live preview at localhost:8000
mkdocs build        # static output in site/
```
