{-# LANGUAGE DataKinds #-}
-- DataKinds lets us use string literals like "api" and "shorten" as types.
-- Normally "api" is just a value (a string). With DataKinds it can live
-- at the type level, which is how Servant builds routes out of them.

{-# LANGUAGE TypeOperators #-}
-- TypeOperators lets us use :> and :<|> as operators between types.
-- Without this, Haskell wouldn't know how to read them.

module Api where

import Data.Text (Text)
-- Text is Haskell's efficient string type. We use it for the short code
-- in the URL (the /:code part) because that's what we'll capture from the path.

import Servant
-- This brings in all the routing building blocks:
-- :>, :<|>, Capture, ReqBody, Get, Post, Verb, Headers, Header,
-- NoContent, Proxy, and more.

import Types
-- Our own types: ShortenRequest, ShortenResponse, StatsResponse.
-- Servant uses these to know what shape the request body and responses are.


-- | The full API type — this is the "menu" of everything our server can handle.
-- Each route is separated by :<|> which means "or this one".
-- Read it top to bottom as three options the server accepts.
type API

  -- Route 1: POST /api/shorten
  -- A client sends us a long URL in the request body (as JSON).
  -- We respond with a short URL (also as JSON).
  = "api" :> "shorten"          -- the path: /api/shorten
      :> ReqBody '[JSON] ShortenRequest   -- expects a JSON body matching ShortenRequest
      :> Post '[JSON] ShortenResponse     -- responds with JSON matching ShortenResponse

  -- Route 2: GET /:code
  -- A client visits a short code like /abc123.
  -- We respond with a 302 redirect — no body, just a Location header
  -- pointing to the original long URL. The browser follows it automatically.
  :<|> Capture "code" Text               -- captures whatever is in /:code as Text
      :> Verb 'GET 302 '[JSON]           -- GET request that returns HTTP 302
          (Headers '[Header "Location" Text] NoContent)
          -- the response has a Location header (where to redirect)
          -- and no body (NoContent)

  -- Route 3: GET /api/stats/:code
  -- A client wants to see stats for a short link (how many clicks, etc).
  -- We respond with a JSON stats object.
  :<|> "api" :> "stats"                  -- the path: /api/stats/...
      :> Capture "code" Text             -- captures the short code from the URL
      :> Get '[JSON] StatsResponse       -- GET request, responds with JSON StatsResponse


-- | A Proxy is a messenger for the API type.
-- Haskell types disappear at runtime, but Servant needs to know which API
-- type to use when starting the server. Proxy carries that info without
-- holding any actual data — it's just a label.
api :: Proxy API
api = Proxy
