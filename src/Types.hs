{-# LANGUAGE DeriveGeneric #-}
-- DeriveGeneric: lets GHC auto-generate Generic instances,
-- which Aeson uses to derive ToJSON/FromJSON without boilerplate.

{-# LANGUAGE OverloadedStrings #-}
-- OverloadedStrings: string literals like "hello" become Text, not String.

module Types where

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
