# Servant & Type-Level Routing

Servant encodes your entire API as a **Haskell type**. The compiler checks that your handlers match the routes — if a route expects a `POST` with a JSON body, your handler *must* accept that shape or it won't compile.

## The core operators

```haskell
-- :> chains path segments and modifiers
-- :<|> separates alternative routes
type API
  = "api" :> "shorten" :> ReqBody '[JSON] ShortenRequest :> Post '[JSON] ShortenResponse
  :<|> Capture "code" Text :> Verb 'GET 302 '[JSON] (Headers '[Header "Location" Text] NoContent)
  :<|> "api" :> "stats" :> Capture "code" Text :> Get '[JSON] StatsResponse
```

Read `:>` as **"then"** — `"api" :> "shorten"` means path `/api/shorten`.

Read `:<|>` as **"or"** — it separates independent routes.

## Why this matters

If you add a route to the type but forget the handler, GHC refuses to compile. You literally cannot deploy a broken API.

## Proxy pattern

```haskell
api :: Proxy API
api = Proxy
```

Types disappear at runtime in Haskell. `Proxy` is a zero-cost wrapper that carries the type information so Servant can reference it when starting the server.
