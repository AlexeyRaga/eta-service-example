module Options where

import           Data.Semigroup      ((<>))
import           Kafka
import           Options.Applicative
import           Text.Read           (readEither)


data Options = Options
  { optKafkaBroker      :: BrokerAddress
  , optKafkaPollTimeout :: Millis
  , optKafkaGroupId     :: ConsumerGroupId
  , optChatTopic        :: TopicName
  } deriving (Show)

options :: Parser Options
options = Options
  <$> ( BrokerAddress <$> strOption
        (  long "kafka-broker"
        <> short 'b'
        <> metavar "ADDRESS:PORT"
        <> help "Kafka bootstrap broker"
        ))
  <*> (Millis <$> readOption
        (  long "kafka-poll-timeout-ms"
        <> short 'u'
        <> metavar "KAFKA_POLL_TIMEOUT_MS"
        <> showDefault <> value 1000
        <> help "Kafka poll timeout (in milliseconds)"))
  <*> ( ConsumerGroupId <$> strOption
        (  long "kafka-group-id"
        <> short 'g'
        <> metavar "GROUP_ID"
        <> showDefault <> value "ex-chat-1"
        <> help "Kafka consumer group id"))
  <*> ( TopicName <$> strOption
        (  long "chat-topic"
        <> short 'i'
        <> metavar "TOPIC"
        <> help "Input topic"))

readOption :: Read a => Mod OptionFields a -> Parser a
readOption = option $ eitherReader readEither

optionsParser :: ParserInfo Options
optionsParser = info (helper <*> options)
  (  fullDesc
  <> progDesc "Eta Service Example"
  <> header "Eta Service Example"
  )

parseOptions :: IO Options
parseOptions = execParser optionsParser
