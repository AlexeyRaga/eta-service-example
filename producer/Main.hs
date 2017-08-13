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
  T.putStrLn "Enter messages (one per line)"

  runConduitRes $
    userMessagesSource
    .| L.map (mkProdRecord (optInputTopic opt))
    .| kafkaSink (producerProps opt)

producerProps :: Options -> ProducerProperties
producerProps opts = producerBrokersList [optKafkaBroker opts]

userMessagesSource :: MonadIO m => Source m Message
userMessagesSource = yieldM (parseMessage <$> (liftIO T.getLine)) >> userMessagesSource

mkProdRecord :: ToAvro a => TopicName -> a -> ProducerRecord
mkProdRecord t v = ProducerRecord t Nothing Nothing (Just . BL.toStrict $ Avro.encode v)

parseMessage :: Text -> Message
parseMessage l = Message
  { messageTo   = if T.null to then Nothing else Just to
  , messageText = T.dropWhile isSpace txt
  }
  where
    line = l & T.stripStart & T.dropWhile isSpace
    (to, txt) = if T.isPrefixOf "@" line
                  then line & T.drop 1 & T.breakOn " "
                  else ("", line)

