# How Curtail Works

## Request flow

```
Client POST /api/shorten {"url": "https://example.com"}
  → Servant parses + validates (type-safe, compile-time checked)
  → Handler generates 7-char code, inserts into SQLite
  → Returns {"code": "aB3kZ9m", "short_url": "http://localhost:8080/aB3kZ9m"}

Client GET /aB3kZ9m
  → Servant captures "aB3kZ9m" from path
  → Handler looks up code, increments clicks, returns 302 + Location header
  → Browser follows redirect to original URL
```

## Project structure

```
curtail/
├── src/
│   ├── Api.hs        # Route type definitions
│   ├── Config.hs     # Env var config (PORT, DB_PATH, BASE_URL)
│   ├── Db.hs         # Persistent schema + DB operations
│   ├── Handlers.hs   # Request handlers + AppEnv
│   ├── Main.hs       # Entry point — wires everything together
│   └── Types.hs      # Request/response types + JSON instances
├── gleam-expiry/      # (coming soon) OTP background worker
│   ├── src/expiry.gleam
│   └── src/sql.gleam
└── docs/              # These learning notes (MkDocs Material)
```

## Key design choices

- **Servant** for compile-time route safety — impossible to deploy with mismatched handlers
- **SQLite** for simplicity — single file, no server process
- **Gleam/OTP** for the background worker — crash-restart supervision without touching Haskell code
