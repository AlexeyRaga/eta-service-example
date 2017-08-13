{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Control.Monad.Catch
import           Control.Monad.IO.Class

import           Control.Concurrent
import           Data.Avro              as Avro
import           Data.ByteString        as BS
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

newtype AppError = AppError String deriving (Show, Eq)
instance Exception AppError

main :: IO ()
main = do
  opt <- parseOptions

  runConduitRes $
    kafkaSource (consumerProps opt) (Millis 3000) [optInputTopic opt]
    .| L.concat
    .| L.map crValue
    .| L.catMaybes
    .| L.map decodeMessage
    .| L.mapM (either throwM return)
    .| L.mapM_ (liftIO . print)

consumerProps :: Options -> ConsumerProperties
consumerProps opts =
  consumerBrokersList [optKafkaBroker opts]
  <> groupId (optKafkaGroupId opts)
  <> autoCommit (Millis 6000)
  <> offsetReset Earliest

decodeMessage :: BS.ByteString -> Either AppError Message
decodeMessage = resultToEither . Avro.decode messageSchema . BL.fromStrict

resultToEither :: Result a -> Either AppError a
resultToEither (Success a) = Right a
resultToEither (Error e)   = Left (AppError e)

