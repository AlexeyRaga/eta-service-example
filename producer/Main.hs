{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Control.Monad.IO.Class

import           Control.Concurrent
import           Data.Avro              as Avro
import           Data.ByteString.Lazy   as BL
import           Data.Char
import           Data.Conduit
import           Data.Conduit.List      as L
import           Data.Function          ((&))
import           Data.Monoid            ((<>))
import           Data.Text              as T
import           Data.Text.IO           as T
import           Kafka
import           Kafka.Conduit

import           Contract
import           Options

main :: IO ()
main = do
  opt <- parseOptions

  runConduitRes $
    userMessagesSource                          -- read stream of ChatMessage from the console
    .| L.map (mkProdRecord (optChatTopic opt))  -- convert each ChatMessage to ProducerRecord
    .| kafkaSink (producerProps opt)            -- send each ProducerRecord to Kafka

-- | Create producer properties
producerProps :: Options -> ProducerProperties
producerProps opts =
  producerBrokersList [optKafkaBroker opts]    -- at least one "bootstrap" broker address (host:port)

-- | Source of messages which user types in his/her console
userMessagesSource :: MonadIO m => Source m ChatMessage
userMessagesSource =
  yieldM (parseMessage <$> (liftIO T.getLine)) >> userMessagesSource

-- | Wrap chat message into ProducerRecord
mkProdRecord :: ToAvro a => TopicName -> a -> ProducerRecord
mkProdRecord t v = ProducerRecord
  t                                    -- target topic
  Nothing                              -- no specific partition
  Nothing                              -- no specified key (could be a chat room name)
  (Just . BL.toStrict $ Avro.encode v) -- payload encoded in Avro

-- | Parses user's text into ChatMessage
-- A message can be a plain text or a text prefixed with "@username"
parseMessage :: Text -> ChatMessage
parseMessage l = ChatMessage
  { messageTo   = if T.null to then Nothing else Just to
  , messageText = T.dropWhile isSpace txt
  }
  where
    line = l & T.stripStart & T.dropWhile isSpace
    (to, txt) = if T.isPrefixOf "@" line
                  then line & T.drop 1 & T.breakOn " "
                  else ("", line)

