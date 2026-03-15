# Persistent & SQLite

Persistent is Haskell's database ORM. You define your schema in a DSL and it generates types, migrations, and query functions at compile time via Template Haskell.

## Schema definition

```haskell
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
UrlEntry
    code      Text
    longUrl   Text
    clicks    Int       default=0
    createdAt UTCTime   default=CURRENT_TIME
    UniqueCode code
    deriving Show Eq
|]
```

This generates:

- A `UrlEntry` Haskell type with field accessors (`urlEntryCode`, `urlEntryLongUrl`, etc.)
- A `migrateAll` function that runs `CREATE TABLE IF NOT EXISTS`
- A `UniqueCode` constraint for deduplication

## Running queries

```haskell
-- All DB operations live in ReaderT SqlBackend IO
lookupUrl :: Text -> ReaderT SqlBackend IO (Maybe UrlEntry)
lookupUrl code = fmap entityVal <$> getBy (UniqueCode code)
```

`getBy` returns `Maybe (Entity UrlEntry)` — the `Entity` wrapper holds the database key + the value. `entityVal` strips the key when you don't need it.

## Connection pooling

```haskell
withSqlitePool "urls.db" 10 $ \pool -> do
  runSqlPool (runMigration migrateAll) pool
```

!!! note
    `migrateAll` is a `Migration`, not a raw query. Wrap it with `runMigration` before passing to `runSqlPool`.
