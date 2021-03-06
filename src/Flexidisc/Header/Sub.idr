module Flexidisc.Header.Sub

import Flexidisc.Header.Label
import Flexidisc.Header.Row
import Flexidisc.Header.Type
import Flexidisc.OrdList

%default total
%access public export

data Sub : (xs, ys : Header' k a) -> Type where
  S : {xs : OrdList k o a} -> {ys : OrdList k o a} ->
      Sub xs ys -> Sub (H xs) (H ys)

%hint
public export
rowFromSub : Sub xs ys -> Row key ty xs -> Row key ty ys
rowFromSub (S sub) (R lbl) = R (rowFromSub sub lbl)

%hint
public export
labelFromSub : Sub xs ys -> Label x xs -> Label x ys
labelFromSub (S sub) (L lbl) = L (labelFromSub sub lbl)
