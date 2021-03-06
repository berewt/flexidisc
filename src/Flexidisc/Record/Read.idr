module Flexidisc.Record.Read

import        Flexidisc.RecordContent
import public Flexidisc.Record.Type

%default total
%access export

||| Get value from a `Row`
||| (not the most convenient way to get a value
||| but it may be useful when you have a `Row`)
|||
||| Complexity is _O(n)_
atRow : RecordM m k header -> (loc : Row l ty header) -> m ty
atRow (Rec xs _) (R loc) = atRow xs loc

||| Get value from a `Label`
||| (not the most convenient way to get a value
||| but it may be useful when you have a `Label`)
|||
||| It's slightly less efficient than `atRow`,
||| as you need to go through the header to get the return type
|||
||| Complexity is _O(n)_
atLabel : RecordM m k header -> (loc : Label l header) -> m (atLabel header loc)
atLabel (Rec xs _) (L loc) = atLabel xs loc

||| Typesafe extraction of a value from a record
|||
||| Complexity is _O(n)_
get : (query : k) -> RecordM m k header ->
      {auto loc : Row query ty header} -> m ty
get query xs {loc} = atRow xs loc

||| Typesafe extraction of a value from a record,
||| `Nothing` if the Row doesn't exist.
|||
||| Complexity is _O(n)_
export
lookup : (Ord k, DecEq k) =>
         (query : k) -> (xs : RecordM m k header) ->
         {auto p : HereOrNot [(query, ty)] header} -> Maybe (m ty)
lookup _ xs {p = (HN p)} = (atRow xs . R) <$> (toRow p)

infixl 7 !!

||| (Almost) infix alias for `get`
|||
||| Almost: it requires an implicit paramet which may leads to weird behaviour
||| when used as an infix operator
(!!) : RecordM m k header -> (query : k) ->
      {auto loc : Row query ty header} -> m ty
(!!) rec field = get field rec
