module KafkaUtils where

import           Control.Monad                (void)
import           Control.Monad.Trans.Resource
import           Data.Foldable
import           Data.Function                ((&))
import           Data.Monoid                  ((<>))
import           Kafka.Conduit
import           Options


consumerProps :: Options -> ConsumerProperties
consumerProps opts =
  consumerBrokersList [optKafkaBroker opts]
  <> groupId (optKafkaGroupId opts)
  <> autoCommit (Millis 6000)
  <> offsetReset Earliest

producerProps :: Options -> ProducerProperties
producerProps opts = producerBrokersList [optKafkaBroker opts]

