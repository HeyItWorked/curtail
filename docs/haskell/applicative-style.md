# Applicative Style

The `Config.hs` compile error we hit is a classic Haskell gotcha. Here's why it matters.

## The pattern

```haskell
instance Envy.FromEnv Config where
  fromEnv _ = Config
    <$> (maybe 8080 id <$> Envy.envMaybe "PORT")
    <*> (maybe "urls.db" id <$> Envy.envMaybe "DB_PATH")
    <*> Envy.env "BASE_URL"
```

This builds a `Config` from three effectful values. Read it as:

> "Take the `Config` constructor and apply it across three environment lookups."

- `<$>` applies a pure function to the first wrapped value
- `<*>` feeds each additional wrapped value into the partially-applied function

## The indentation trap

```haskell
-- BROKEN — GHC thinks Config is the complete return value
fromEnv _ = Config
<$> ...   -- parse error: <$> starts a new statement

-- FIXED — indented deeper = continuation of the expression above
fromEnv _ = Config
    <$> ...
```

Haskell uses indentation to determine what belongs to what. If `<$>` is at the same indent level as `fromEnv`, GHC treats it as a new declaration, not a continuation.

!!! tip
    When chaining `<$>` and `<*>`, always indent them deeper than the `=` on the line above.
