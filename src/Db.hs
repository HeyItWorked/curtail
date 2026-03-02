{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
-- Note: these pragmas are not written by hand each time.
-- Persistent's documentation lists exactly which extensions its generated code needs.
-- In practice: attempt to compile, GHC tells you which are missing.

module Db where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT)
import Data.Text (Text)
import Data.Time (UTCTime, getCurrentTime)
import Database.Persist
import Database.Persist.Sql (SqlBackend)
import Database.Persist.TH

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
-- share runs mkPersist and mkMigrate together at compile time (Template Haskell).
-- mkPersist sqlSettings  — generates the UrlEntry Haskell type from the DSL below
-- mkMigrate "migrateAll" — generates migrateAll, run at startup to CREATE TABLE IF NOT EXISTS
-- persistLowerCase       — maps camelCase field names to snake_case SQL columns

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
UrlEntry
    code      Text
    longUrl   Text
    clicks    Int       default=0
    createdAt UTCTime   default=CURRENT_TIME
    UniqueCode code
    deriving Show Eq
|]

-- ---------------------------------------------------------------------------
-- Operations
-- ---------------------------------------------------------------------------

-- | Store a new short URL, guarding against duplicate codes.
-- Returns Left "Code exists" if the code is already taken,
-- Right () on success.
-- Note: the UniqueCode constraint in the schema would also reject duplicates
-- at the DB level, but checking first gives us a clean error to return.
insertUniqueUrl :: Text -> Text -> ReaderT SqlBackend IO (Either String ())
insertUniqueUrl code longUrl = do
  existing <- getBy $ UniqueCode code
  case existing of
    Just _  -> return $ Left "Code exists"
    Nothing -> do
      now <- liftIO getCurrentTime
      -- insert_ discards the returned Key (we don't need it)
      insert_ $ UrlEntry code longUrl 0 now
      return $ Right ()

-- | Look up a URL record by its short code.
-- fmap entityVal unwraps the Entity wrapper to give us just UrlEntry.
-- <$> applies that unwrap inside the Maybe (so Maybe (Entity UrlEntry) → Maybe UrlEntry).
-- Returns Nothing if the code does not exist.
lookupUrl :: Text -> ReaderT SqlBackend IO (Maybe UrlEntry)
lookupUrl code = fmap entityVal <$> getBy (UniqueCode code)

-- | Increment the click counter for a row matched by code.
-- updateWhere: find all rows where UrlEntryCode == code, apply the update.
-- UrlEntryClicks +=. 1: Persistent-generated field selector + increment operator.
-- Takes Text (the code) rather than a Key — no need to fetch the row first.
incrementClicks :: Text -> ReaderT SqlBackend IO ()
incrementClicks code =
  updateWhere [UrlEntryCode ==. code] [UrlEntryClicks +=. 1]
