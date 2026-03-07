{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module Config where

import Data.Text (Text)
import qualified System.Envy as Envy
import GHC.Generics (Generic)
import System.Exit (die)

data Config = Config
  { configPort :: Int
  , configDbPath :: Text
  , configBaseUrl :: Text
  } deriving (Generic, Show)

instance Envy.FromEnv Config where
  fromEnv _ = Config
  -- Read it as: "build a Config by pulling each field from the environment in order"
  -- <$> applies the Config constructor to the first IO-wrapped value (configPort)
  -- <*> feeds each subsequent field into the constructor (configDbPath, configBaseUrl)
  --
  -- envMaybe "PORT"  → tries to read $PORT; returns Nothing if unset, Just value if set
  -- maybe 8080 id    → if Nothing use 8080, if Just x return x as-is (id = identity)
  -- read as: "try to read PORT from the environment, fall back to 8080 if missing"
  <$> (maybe 8080 id <$> Envy.envMaybe "PORT")
  -- read as: "try to read DB_PATH from the environment, fall back to urls.db if missing"
  <*> (maybe "urls.db" id <$> Envy.envMaybe "DB_PATH")
  -- env "BASE_URL" (no Maybe) = required field, no default
  -- read as: "read BASE_URL from the environment — crash at startup if it is not set"
  <*> Envy.env "BASE_URL"

-- | Load config from environment variables, crashing with a clear message
-- if anything required is missing (i.e. BASE_URL is not set).
getConfig :: IO Config
getConfig = do
  eitherConfig <- Envy.decodeEnv
  case eitherConfig of
    Left err  -> die $ "Configuration error: " ++ show err
    Right cfg -> return cfg