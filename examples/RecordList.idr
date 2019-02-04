module RecordList

import CleanRecord
import CleanRecord.RecordList
import CleanRecord.Selection

||| `RecordList` are Heterogeneous lists of record
people : RecordList [ [ "firstname" := String
                      , "lastname" := String
                      , "age" := Nat
                      , "location" := Maybe String]
                    , [ "firstname" := String
                      , "location" := String
                      ]
                    ]
people = [ namedRec [ "firstname" ::= "John"
                    , "lastname" ::= "Doe"
                    , "age" ::= 42
                    , "location" ::= Nothing
                    ]
         , namedRec [ "firstname" ::= "Waldo"
                    , "location" ::= "Hidden"
                    ]
         ]

||| We can find the first record that amtch the partial information we provide
whereIsWaldo : Maybe (header : List (Field String) ** Record header)
whereIsWaldo = matchOne (namedRec ["firstname" ::= "Waldo"]) people

||| We can find the first record that amtch the partial information we provide
whereIsDoe : Maybe (header : List (Field String) ** Record header)
whereIsDoe = matchOne (namedRec ["lastname" ::= "Doe"]) people

||| We can find the first record that amtch the partial information we provide
selectWaldo : List (Maybe (Record ["firstname" := String]))
selectWaldo = let
  stmt = namedSel ["firstname" ::= \x => guard (x == "Waldo") *> pure x]
  in selectMapM stmt people

||| You can even search for something that is not available in every record
whoIs42 : Maybe (header : List (Field String) ** Record header)
whoIs42 = matchOne (namedRec ["age" ::= the Nat 42]) people


-- with one limitation, if you look for a specific row,
-- it should have the same type in every rows it's defined
--
-- this would fail:
--
-- whoIsHidden : Maybe (header : List (Field String) ** Record header)
-- whoIsHidden = matchOne (namedRec ["location" ::= "Hidden"]) people
