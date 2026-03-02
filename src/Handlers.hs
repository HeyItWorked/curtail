{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
-- RecordWildCards: lets us write `ShortenRequest{..}` in a function argument
-- and have all its fields (like `shortenUrl`) available as plain variables
-- without manually unpacking them.

{-# LANGUAGE OverloadedStrings #-}
-- Lets string literals like "http://" work as Text, not just String.

module Handlers where

import Config (Config, configBaseUrl)
import Db
import Types

import Control.Monad (replicateM, unless)
-- replicateM n action: run `action` n times and collect the results into a list.
-- We use it to generate 7 random characters in one go.
-- unless condition action: run `action` only if `condition` is False.
-- We use it to reject URLs that don't start with http:// or https://.

import Control.Monad.IO.Class (liftIO)
-- liftIO: takes a plain IO action and makes it work inside our ReaderT stack.
-- You need this any time you call something that lives in IO (like randomRIO).

import Control.Monad.Reader (ReaderT, asks)
-- ReaderT: the monad transformer that gives every handler invisible access to AppEnv.
-- asks: reach into the AppEnv bag and pull out a field.

import Control.Monad.Trans.Class (lift)
-- lift: take an action from one monad layer and bring it up to the next.
-- We use it to call jsonError (which lives in Handler) from inside ReaderT.

import Data.Aeson (encode)
-- encode: turn a Haskell value into a JSON ByteString.
-- Used when building error response bodies.

import Data.Text (Text)
import qualified Data.Text as T
-- T.isPrefixOf: check if a Text starts with a given prefix.
-- T.pack: convert a regular String into Text.

import Database.Persist.Sql (SqlBackend, runSqlPool, ConnectionPool)
-- SqlBackend: the database connection type Persistent uses.
-- runSqlPool: run a database action against a connection from the pool.
-- ConnectionPool: a pool of reusable database connections.

import Servant (Header, Headers(..), NoContent(..), addHeader, throwError)
-- addHeader: attach a header to a response (used for the Location redirect header).
-- throwError: abort a handler and return an HTTP error to the client.
-- NoContent: a response body type meaning "no body, just headers/status".

import Servant.Server
-- Brings in Handler, ServerError, err400, err404, err500, etc.

import System.Random (randomRIO)
-- randomRIO (lo, hi): generate a random number between lo and hi in IO.


-- ---------------------------------------------------------------------------
-- AppEnv — the shared bag every handler can reach into
-- ---------------------------------------------------------------------------

-- | Holds everything handlers need access to.
-- Instead of passing pool and config to every function, we put them here
-- and use ReaderT to make this available everywhere automatically.
data AppEnv = AppEnv
  { appPool   :: ConnectionPool  -- database connection pool
  , appConfig :: Config          -- app config (base URL, port, db path)
  }


-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- | Generate a random 7-character short code.
-- Uses letters (upper + lower) and digits — 62 possible characters.
-- 62^7 ≈ 3.5 trillion combinations, so collisions are extremely rare.
generateCode :: IO Text
generateCode = T.pack <$> replicateM 7 (randomRIO (0, 61) >>= \i ->
  return ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" !! i))
  -- !! i: index into the character list with i
  -- So randomRIO gives us a number 0–61, and we use it to pick a character

-- | Return a structured JSON error response with the given HTTP status.
-- `baseErr` is something like err400 or err404 — we copy it and fill in
-- the body and Content-Type header so the client gets proper JSON back.
jsonError :: ServerError -> Text -> Handler a
jsonError baseErr msg = throwError baseErr
  { errBody    = encode (ErrorResponse msg)  -- JSON-encode the error message
  , errHeaders = [("Content-Type", "application/json")]
  }

-- | Run a database action using the connection pool from AppEnv.
-- Our DB functions (insertUniqueUrl, lookupUrl, etc.) live in
-- `ReaderT SqlBackend IO` — they need a connection to run.
-- `runSqlPool` grabs a connection from the pool, runs the action, returns the result.
runDb :: ReaderT SqlBackend IO a -> ReaderT AppEnv Handler a
runDb action = do
  pool <- asks appPool       -- pull the pool out of our AppEnv bag
  liftIO $ runSqlPool action pool  -- run the DB action with that pool


-- ---------------------------------------------------------------------------
-- Handlers
-- ---------------------------------------------------------------------------

-- | POST /api/shorten
-- Receives a long URL, validates it, generates a short code, saves it, returns it.
createShortUrlHandler :: ShortenRequest -> ReaderT AppEnv Handler ShortenResponse
createShortUrlHandler ShortenRequest{..} = do
  -- RecordWildCards makes `shortenUrl` available directly (from ShortenRequest)

  -- Reject the request if the URL doesn't start with http:// or https://
  -- `unless` runs the second argument only when the condition is False
  unless (T.isPrefixOf "http://" shortenUrl || T.isPrefixOf "https://" shortenUrl) $
    lift $ jsonError err400 "URL must begin with http:// or https://"

  -- Try to insert with a unique code, retrying up to 5 times if there's a collision.
  -- Defined as a local function so it can close over `shortenUrl` from above.
  let insertWithRetry :: Int -> ReaderT AppEnv Handler Text
      insertWithRetry remainingTries = do
        code   <- liftIO generateCode          -- generate a candidate code in IO
        result <- runDb $ insertUniqueUrl code shortenUrl  -- try to save it
        case result of
          Right _ -> return code               -- success — return the code
          Left _  | remainingTries > 0
                  -> insertWithRetry (remainingTries - 1)  -- collision, try again
                  | otherwise
                  -> lift $ jsonError err500 "Failed to generate unique code"
                  -- gave up after 5 tries — extremely unlikely in practice

  finalCode <- insertWithRetry (5 :: Int)

  -- Pull the base URL out of config so we can build the full short URL
  base <- asks (configBaseUrl . appConfig)

  return ShortenResponse
    { responseCode     = finalCode
    , responseShortUrl = base <> "/" <> finalCode  -- e.g. "http://localhost:8080/aB3kZ9m"
    }


-- | GET /:code
-- Looks up the short code and sends a 302 redirect to the original URL.
-- Also increments the click counter.
redirectHandler :: Text -> ReaderT AppEnv Handler (Headers '[Header "Location" Text] NoContent)
redirectHandler code = do
  mUrl <- runDb $ lookupUrl code  -- returns Nothing if code doesn't exist
  case mUrl of
    Nothing  -> lift $ jsonError err404 "Short URL not found"
    Just url -> do
      runDb $ incrementClicks code              -- count this visit
      return $ addHeader (urlEntryLongUrl url) NoContent
      -- addHeader puts the original URL into the Location header
      -- the browser reads that header and navigates there automatically


-- | GET /api/stats/:code
-- Returns click stats for a short URL — no redirect, just data.
statsHandler :: Text -> ReaderT AppEnv Handler StatsResponse
statsHandler code = do
  mUrl <- runDb $ lookupUrl code
  case mUrl of
    Nothing  -> lift $ jsonError err404 "Short URL not found"
    Just url -> return StatsResponse
      { statsCode      = urlEntryCode      url
      , statsLongUrl   = urlEntryLongUrl   url
      , statsClicks    = urlEntryClicks    url
      , statsCreatedAt = urlEntryCreatedAt url
      -- urlEntry* are field accessors generated by Persistent from the schema in Db.hs
      }
