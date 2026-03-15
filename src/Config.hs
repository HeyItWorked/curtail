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
    <$> (maybe 8080 id <$> Envy.envMaybe "PORT")
    <*> (maybe "urls.db" id <$> Envy.envMaybe "DB_PATH")
    <*> Envy.env "BASE_URL"

-- | Load config from environment variables, crashing with a clear message
-- if anything required is missing (i.e. BASE_URL is not set).
getConfig :: IO Config
getConfig = do
  eitherConfig <- Envy.decodeEnv
  case eitherConfig of
    Left err  -> die $ "Configuration error: " ++ show err
    Right cfg -> return cfg