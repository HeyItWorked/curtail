# curtail

A type-safe URL shortener in Haskell.

Built with [Servant](https://docs.servant.dev/) + SQLite via [persistent](https://hackage.haskell.org/package/persistent).

## API

| Method | Route | Description |
|--------|-------|-------------|
| `POST` | `/api/shorten` | Create a short URL |
| `GET` | `/:code` | Redirect to original URL |
| `GET` | `/api/stats/:code` | View click stats |

## Running

```bash
export BASE_URL=http://localhost:8080
stack run
```

Optional env vars: `PORT` (default `8080`), `DB_PATH` (default `urls.db`).
