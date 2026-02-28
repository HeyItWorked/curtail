{-# LANGUAGE DeriveGeneric #-}
-- DeriveGeneric: lets GHC auto-generate Generic instances,
-- which Aeson uses to derive ToJSON/FromJSON without boilerplate.

{-# LANGUAGE OverloadedStrings #-}
-- OverloadedStrings: string literals like "hello" become Text, not String.

module Types where

import Data.Aeson
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics

-- | POST /api/shorten — request body
data ShortenRequest = ShortenRequest
  { shortenUrl :: Text
  } deriving (Generic, Show)

-- | POST /api/shorten — success response
data ShortenResponse = ShortenResponse
  { responseCode     :: Text  -- the generated short code, e.g. "aB3kZ9m"
  , responseShortUrl :: Text  -- full URL, e.g. "http://localhost:8080/aB3kZ9m"
  } deriving (Generic, Show)

-- | GET /api/stats/:code — response
data StatsResponse = StatsResponse
  { statsCode      :: Text
  , statsLongUrl   :: Text
  , statsClicks    :: Int
  , statsCreatedAt :: UTCTime
  } deriving (Generic, Show)

-- | Used by all error responses
data ErrorResponse = ErrorResponse
  { errorMessage :: Text
  } deriving (Generic, Show)

-- Generic JSON instances
-- Pattern: strip the Haskell field prefix, then convert camelCase to snake_case.
-- e.g. responseShortUrl -> drop 8 -> ShortUrl -> camelTo2 '_' -> short_url

instance ToJSON ShortenRequest where
  toJSON = genericToJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 7 }  -- drop "shorten"

instance FromJSON ShortenRequest where
  parseJSON = genericParseJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 7 }

instance ToJSON ShortenResponse where
  toJSON = genericToJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 8 }  -- drop "response"

instance FromJSON ShortenResponse where
  parseJSON = genericParseJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 8 }

instance ToJSON StatsResponse where
  toJSON = genericToJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 5 }  -- drop "stats"

instance FromJSON StatsResponse where
  parseJSON = genericParseJSON defaultOptions
    { fieldLabelModifier = camelTo2 '_' . drop 5 }
