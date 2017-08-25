module Main where

import           Control.Monad.Catch
import           Control.Monad.IO.Class

import           Control.Concurrent
import           Data.Avro              as Avro
import           Data.ByteString        as BS
import           Data.ByteString.Char8  as C8
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
    kafkaSource (consumerProps opt) (Millis 3000) [optChatTopic opt]
    .| L.concat                  -- kafkaSource returns batches, let's flatten them
    .| L.map crValue             -- only extract payload from ConsumerRecord
    .| L.catMaybes               -- there can be messages with no payload, skip them
    .| L.map decodeMessage       -- deserialise Avro message
    .| L.mapM_ (liftIO . print)  -- do something with the message, for example print

-- | Create consumer properties
consumerProps :: Options -> ConsumerProperties
consumerProps opts =
  consumerBrokersList [optKafkaBroker opts]  -- at least one "bootstrap" broker address (host:port)
  <> groupId (optKafkaGroupId opts)          -- specify the consumer group ID
  <> autoCommit (Millis 6000)                -- commit offsets automatically
  <> offsetReset Earliest                    -- when there are no offsets committes, start from the beginning

-- | Deserialise message using Avro serialiser
decodeMessage :: BS.ByteString -> Either AppError ChatMessage
decodeMessage = resultToEither . Avro.decode chatMessageSchema . BL.fromStrict

resultToEither :: Result a -> Either AppError a
resultToEither (Success a) = Right a
resultToEither (Error e)   = Left (AppError e)

