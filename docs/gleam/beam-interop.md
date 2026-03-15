# BEAM Interop

*This page will be filled in when we connect Gleam to the Haskell app's SQLite database.*

## The idea

The Haskell app and Gleam worker share the same SQLite file. They don't talk to each other directly — they coordinate through the database.

```
┌─────────────┐     ┌──────────────┐
│  Haskell    │     │  Gleam       │
│  (Servant)  │────▶│  (OTP actor) │
│  CRUD URLs  │     │  cleanup     │
└──────┬──────┘     └──────┬───────┘
       │                   │
       ▼                   ▼
    ┌─────────────────────────┐
    │     curtail.db (SQLite) │
    └─────────────────────────┘
```

This is a simple, battle-tested pattern: multiple processes sharing a database file. SQLite handles the locking.
