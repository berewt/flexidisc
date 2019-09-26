module Flexidisc.Record.Type

import        Flexidisc.RecordContent
import public Flexidisc.THList

import public Flexidisc.OrdHeader
import public Flexidisc.Dec.IsYes
import public Flexidisc.Header
import public Flexidisc.TaggedValue

%default total
%access export

-- CREATE

||| A `Record` is a set of rows
||| @ k      The type of the labels
||| @ header The list of rows into the record, with their types
public export
data Record : (k : Type) -> (header : Header k) -> Type where
  Rec : (o : Ord k) =>
        (values : RecordContent k o header) -> (nubProof : Nub header) ->
        Record k (H header)

infix 6 :::

||| Convenient helper for row type readability
public export
(:::) : (k : l) -> (v : Type) -> Pair l Type
(:::) = MkPair


%name Record xs, ys, zs

||| The empty record
public export
Nil : Ord k => Record k []
Nil = Rec empty []

||| Insert a new row in a record
public export
cons : (DecEq k, Ord k) => TaggedValue k' ty -> Record k header ->
       {default SoTrue fresh : IsFresh k' header} ->
       Record k ((k',ty) :: header)
cons x (Rec xs isnub) {fresh} =
  Rec (insert x xs) (freshInsert (getProof fresh) isnub)

||| Insert a new row in a record
public export
(::) : (DecEq k, Ord k) => TaggedValue k' ty -> Record k header ->
       {default SoTrue fresh : IsFresh k' header} ->
       Record k ((k',ty) :: header)
(::) = cons

||| It's just monomorphic `id` with a fancy name, to help type inference
rec : Record k header -> Record k header
rec = id

namespace test
  %access private

  test_rec1 : Record String ["Firstname" ::: String]
  test_rec1 = ["Firstname" := "John"]

  test_rec2 : Record String ["Lastname" ::: String, "Firstname" ::: String]
  test_rec2 = ["Firstname" := "John", "Lastname" := "Doe"]
