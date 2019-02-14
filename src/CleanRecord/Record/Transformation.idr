module CleanRecord.Record.Transformation

import CleanRecord.Record
import CleanRecord.RecordContent
import CleanRecord.OrdList.Disjoint
import CleanRecord.OrdList.Nub
import public CleanRecord.Transformation.Type
import public CleanRecord.Transformation.TransHeader

import public Control.Monad.Identity

%default total
%access export

data TransformationM : (m : Type -> Type) -> (k : Type) ->
                       (header : TransHeader k) -> Type where
  Trans : (o : Ord k) =>
          (values : MapValuesM m k o header) ->
          (nubProof : Nub header) ->
          TransformationM m k (T header)

public export
Transformation : (k : Type) -> (header : TransHeader k) -> Type
Transformation = TransformationM Identity

transM : TransformationM m k header -> TransformationM m k header
transM = id

trans : TransformationM Identity k header -> TransformationM Identity k header
trans = id

||| The empty record
Nil : Ord k => TransformationM m k []
Nil = Trans [] []

||| Insert a new row in a record
(::) : (DecEq k, Ord k) => TaggedValue k' (s -> m t) -> TransformationM m k header ->
       {default SoTrue fresh : IsFresh k' header} ->
       TransformationM m k ((k', s :-> t) :: header)
(::) x (Trans xs isnub) {fresh} =
  Trans (insert x xs) (freshInsert (getProof fresh) isnub)

transPreservesFresh : Ord k => (xs : OrdList k MapValue o) -> (y : Fresh l (toSource xs)) -> Fresh l (toTarget xs)
transPreservesFresh [] y = y
transPreservesFresh ((k, s :-> t) :: xs) (f :: fresh) = f :: transPreservesFresh xs fresh

transPreservesNub : (header : OrdList k MapValue o) -> Nub (toSource header) -> Nub (toTarget header)
transPreservesNub [] xs = xs
transPreservesNub ((l, s :-> t) :: xs) (y::ys) = transPreservesFresh xs y :: transPreservesNub xs ys

mapRecordM : Monad m =>
             (trans : TransformationM m k mapper) ->
             (xs : Record k (toSource mapper)) ->
             m (Record k (toTarget mapper))
mapRecordM (Trans trans nubT) (Rec xs nubXS) {mapper = T mapper} =
  map (flip Rec (transPreservesNub mapper nubXS)) (mapRecordM trans xs)

mapRecord : (trans : Transformation k mapper) ->
            (xs : Record k (toSource mapper)) ->
            Record k (toTarget mapper)
mapRecord trans xs = runIdentity (mapRecordM trans xs)


patchM : (DecEq k, Monad m) =>
         (trans : TransformationM m k mapper) ->
         (xs : Record k header) ->
         {auto prf : Sub (toSource mapper) header} ->
         m (Record k (patch (toTarget mapper) header))
patchM (Trans trans nubT) (Rec xs nubXS) {prf = S prf} {mapper = T mapper} = let
  nubProof = disjointNub diffIsDisjoint
                         (isNubFromSub diffIsSub nubXS)
                         (transPreservesNub mapper (isNubFromSub prf nubXS))
  in map (flip Rec nubProof) (patchM trans xs prf)

patch : DecEq k =>
        (trans : Transformation k mapper) ->
        (xs : Record k header) ->
        {auto prf : Sub (toSource mapper) header} ->
        Record k (patch (toTarget mapper) header)
patch trans xs = runIdentity (patchM trans xs)

-- Operators

keepIf : (Alternative m, Applicative m) => (a -> Bool) -> a -> m a
keepIf f x = map (const x) (guard (f x))

is : (Eq a, Alternative m, Applicative m) => a -> a -> m a
is expected = keepIf (== expected)

isnot : (Eq a, Alternative m, Applicative m) => a -> a -> m a
isnot expected = keepIf (/= expected)

