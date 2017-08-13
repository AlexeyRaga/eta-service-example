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
    kafkaSource (consumerProps opt) (Millis 3000) [optInputTopic opt]
    .| L.mapM_ (liftIO . print)

consumerProps :: Options -> ConsumerProperties
consumerProps opts =
  consumerBrokersList [optKafkaBroker opts]
  <> groupId (optKafkaGroupId opts)
  <> autoCommit (Millis 6000)
  <> offsetReset Earliest


