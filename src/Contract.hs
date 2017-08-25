{-# LANGUAGE OverloadedStrings #-}
module Contract where

import           Data.Avro
import           Data.Avro.Schema
import qualified Data.Avro.Types    as AT
import           Data.List.NonEmpty
import           Data.Text

data ChatMessage = ChatMessage
  { messageTo   :: Maybe Text
  , messageText :: Text
  } deriving (Show, Eq)

chatMessageSchema :: Schema
chatMessageSchema =
  Record "ChatMessage" Nothing [] Nothing Nothing
    [ fld "to"        (mkUnion $ Null :| [String])  Nothing
    , fld "text"      String                        Nothing
    ]
    where
     fld nm ty def = Field nm [] Nothing Nothing ty def

instance ToAvro ChatMessage where
  schema = pure chatMessageSchema
  toAvro msg = record chatMessageSchema
             [ "to"         .= messageTo msg
             , "text"       .= messageText msg
             ]

instance FromAvro ChatMessage where
  fromAvro (AT.Record _ r) =
    ChatMessage <$> r .: "to"
                <*> r .: "text"
  fromAvro r = badValue r "ChatMessage"
