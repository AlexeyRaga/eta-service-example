{-# LANGUAGE OverloadedStrings #-}
module Contract where

import           Data.Avro
import           Data.Avro.Schema
import qualified Data.Avro.Types    as AT
import           Data.List.NonEmpty
import           Data.Text

data Message = Message
  { messageTo   :: Maybe Text
  , messageText :: Text
  } deriving (Show, Eq)

messageSchema :: Schema
messageSchema =
  Record "Message" Nothing [] Nothing Nothing
    [ fld "to"        (mkUnion $ Null :| [String])  Nothing
    , fld "text"      String                        Nothing
    ]
    where
     fld nm ty def = Field nm [] Nothing Nothing ty def

instance ToAvro Message where
  schema = pure messageSchema
  toAvro msg = record messageSchema
             [ "to"         .= messageTo msg
             , "text"       .= messageText msg
             ]

instance FromAvro Message where
  fromAvro (AT.Record _ r) =
    Message <$> r .: "to"
            <*> r .: "text"
  fromAvro r = badValue r "Message"
