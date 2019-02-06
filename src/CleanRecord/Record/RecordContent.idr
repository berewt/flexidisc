||| `RecordContent` is the meat of `CleanRecord` without the unicity proof:
||| `RecordContent` can contain duplicated fields, they can be compared to
||| _labelled `HVect`_.
module CleanRecord.Record.RecordContent

import CleanRecord.Elem.Label
import CleanRecord.Elem.Row

import CleanRecord.IsNo
import CleanRecord.Nub

import CleanRecord.Relation.Disjoint
import CleanRecord.Relation.NegSub
import CleanRecord.Relation.OrdSub
import CleanRecord.Relation.Permutation
import CleanRecord.Relation.Sub
import CleanRecord.Relation.Update

%default total
%access export

public export
Field : (label : Type) -> Type
Field label = Pair label Type

public export
data RecordContent : List (Field label) -> Type where
  Nil : RecordContent []
  (::) : ty -> RecordContent header -> RecordContent ((lbl, ty) :: header)

private
test_rc_value_1 : RecordContent [(0, Nat), (1, String)]
test_rc_value_1 = [42, "Test"]

private
test_rc_value_2 : RecordContent [(2, Nat), (3, String)]
test_rc_value_2 = [20170119, "Hi"]


private
test_rc_value_duplicate : RecordContent [(0, Nat), (0, String)]
test_rc_value_duplicate = [42, "Test"]


implementation Eq (RecordContent []) where
  (==) [] [] = True
  (/=) [] [] = False

implementation (Eq t, Eq (RecordContent ts)) => Eq (RecordContent ((a, t)::ts)) where
  (==) (x :: xs) (y :: ys) = x == y && xs == ys
  (/=) (x :: xs) (y :: ys) = x /= y || xs == ys

public export
interface Shows a (ts : List (Field a)) where
  shows : {ts : List (Field a)} -> RecordContent ts -> List String

implementation Shows key [] where
  shows _ = []

implementation (Show key, Show t, Shows key ts) => Shows key ((k,t)::ts) where
  shows (x::xs) {k} = unwords [show k, ":", show x] :: shows xs

implementation (Shows key ts) => Show (RecordContent ts) where
  show xs = "[" ++ concat (intersperse ", " (shows xs)) ++ "]"

(++) : RecordContent left -> RecordContent right -> RecordContent (left ++ right)
(++) [] ys = ys
(++) (x :: xs) ys = x :: xs ++ ys

rename : DecEq label =>
         (oldLabel : label) ->
         (newLabel : label) ->
         RecordContent header ->
         {auto prf : Label oldLabel header} ->
         RecordContent (changeLabel header prf newLabel)
rename oldLabel newLabel (x :: xs) {prf = Here} = x :: xs
rename oldLabel newLabel (x :: xs) {prf = (There later)} =
  x :: rename oldLabel newLabel xs


atRow : (rec : RecordContent xs) -> (loc : Row label ty xs) -> ty
atRow (x :: _)  Here = x
atRow (_ :: xs) (There later) = atRow xs later

ordSub : RecordContent header ->
         (ordsubPrf : OrdSub sub header) ->
         RecordContent sub
ordSub [] Empty = []
ordSub (x :: xs) (Skip sub) = ordSub xs sub
ordSub (x :: xs) (Keep sub) = x :: ordSub xs sub

updateRow : {header : List (Field a)} ->
            (xs : RecordContent header) ->
            (loc : Row k ty header) -> (ty -> tNew) ->
            RecordContent (updateRow header loc tNew)
updateRow (x :: xs) Here f = f x :: xs
updateRow (x :: xs) (There later) f = x :: updateRow xs later f

replaceRow : {header : List (Field a)} ->
            (xs : RecordContent header) ->
            (loc : Label k header) -> tNew ->
            RecordContent (updateLabel header loc tNew)
replaceRow (x :: xs) Here new = new :: xs
replaceRow (x :: xs) (There later) new = x :: replaceRow xs later new

dropRow : {header : List (Field a)} ->
          RecordContent header -> (loc : Label k header) ->
          RecordContent (dropLabel header loc)
dropRow (_ :: xs) Here = xs
dropRow (x :: xs) (There later) = x :: dropRow xs later

project : RecordContent header -> (subPrf : Sub sub header) ->
          RecordContent sub
project [] Empty = []
project (x :: xs) (Skip sub) = project xs sub
project xs (Keep e sub) =
  atRow xs e :: project (dropRow xs (labelFromRow e)) sub

negProject : RecordContent header -> (negPrf : NegSub sub header) ->
             RecordContent sub
negProject [] Empty = []
negProject xs (Skip e sub) = negProject (dropRow xs e) sub
negProject (x::xs) (Keep sub) = x :: negProject xs sub

reorder : RecordContent header -> (permPrf : Permute sub header) ->
          RecordContent sub
reorder [] Empty = []
reorder xs (Keep e sub) =
  atRow xs e :: reorder (dropRow xs (labelFromRow e)) sub

patch : RecordContent header -> RecordContent update ->
        (Patch update header patched) ->
        RecordContent patched
patch xs [] [] = xs
patch xs (y::ys) (loc :: next) = patch (replaceRow xs loc y) ys next

infix 8 ::=

namespace NamedContent

  public export
  data Row : (k : key) -> Type -> Type where
    MkRow : v -> Row k v

  public export
  (::=) : (k : key) -> value -> Row k value
  (::=) k = MkRow

  public export
  data NamedRecordContent : List (Field label) -> Type where
    Nil : NamedRecordContent []
    (::) : Row lbl ty -> NamedRecordContent header -> NamedRecordContent ((lbl, ty) :: header)

  toRecordContent : NamedRecordContent xs -> RecordContent xs
  toRecordContent [] = []
  toRecordContent ((MkRow x) :: xs) = x :: toRecordContent xs
