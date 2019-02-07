module CleanRecord.OrdHeader.Sub

import CleanRecord.Dec.IsYes
import CleanRecord.OrdHeader.Fresh
import CleanRecord.OrdHeader.Label
import CleanRecord.OrdHeader.Nub
import CleanRecord.OrdHeader.Row
import CleanRecord.OrdHeader.Type

%default total
%access private

||| Proof that a `Vect` is a permutation of another vect
public export
data Sub : (xs : OrdHeader k o) -> (ys : OrdHeader k o) -> Type where
  Empty : Sub [] []
  Skip  : Sub xs ys -> Sub xs (y::ys)
  Keep  : Sub xs ys -> Sub (x::xs) (x::ys)

%name Sub sub, issub, ss

||| An empty `List` is an ordered subset of any `Any`
subEmpty' : (xs : OrdHeader k o) -> Sub [] xs
subEmpty' [] = Empty
subEmpty' (_ :: xs) = Skip (subEmpty' xs)

||| An empty `List` is an ordered subset of any `List`
subEmpty : Sub [] xs
subEmpty {xs} = subEmpty' xs

||| A `List` is an ordered subset of itself
subRefl' : (xs : OrdHeader k o) -> Sub xs xs
subRefl' [] = Empty
subRefl' (x :: xs) = Keep (subRefl' xs)

||| A `List` is an ordered subset of itself
subRefl : Sub xs xs
subRefl {xs} = subRefl' xs

freshInSub : Sub xs ys -> Fresh l ys -> Fresh l xs
freshInSub Empty fresh = fresh
freshInSub (Skip sub) (f :: fresh) = freshInSub sub fresh
freshInSub (Keep sub) (f :: fresh) = f :: freshInSub sub fresh

||| If the original vector doesn't contain any duplicate,
||| an orderred subset doesn't contain duplicate as well
export
isNubFromSub : Sub xs ys -> Nub ys -> Nub xs
isNubFromSub Empty y = y
isNubFromSub (Skip sub) (yes :: prf) = isNubFromSub sub prf
isNubFromSub (Keep sub) (yes :: prf) =
  isFreshFromEvidence (freshInSub sub (getProof yes)) :: isNubFromSub sub prf