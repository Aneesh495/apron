% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.ListExt
% Description: Extended list algorithms, combinators, partitioning, slicing,
%              and sequence manipulations for airport schedule analysis.
% =============================================================================

functor
import
   System
export
   Take: Take
   Drop: Drop
   SplitAt: SplitAt
   TakeWhile: TakeWhile
   DropWhile: DropWhile
   Zip: Zip
   ZipWith: ZipWith
   Unzip: Unzip
   Partition: Partition
   GroupBy: GroupBy
   Intersperse: Intersperse
   Flatten: Flatten
   Dedup: Dedup
   Find: Find
   FindIndex: FindIndex
   All: All
   Any: Any
   Chunk: Chunk
   SortWith: SortWith
define

   % --------------------------------------------------------------------------
   % Take: Returns the first N elements of a list
   % --------------------------------------------------------------------------
   fun {Take Xs N}
      if N =< 0 then
         nil
      else
         case Xs
         of nil then nil
         [] H | T then H | {Take T N - 1}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Drop: Removes the first N elements of a list and returns the remainder
   % --------------------------------------------------------------------------
   fun {Drop Xs N}
      if N =< 0 then
         Xs
      else
         case Xs
         of nil then nil
         [] _ | T then {Drop T N - 1}
         end
      end
   end

   % --------------------------------------------------------------------------
   % SplitAt: Partitions list into tuple pair pair(Prefix, Suffix) at index N
   % --------------------------------------------------------------------------
   fun {SplitAt Xs N}
      pair({Take Xs N} {Drop Xs N})
   end

   % --------------------------------------------------------------------------
   % TakeWhile: Takes leading elements satisfying Pred
   % --------------------------------------------------------------------------
   fun {TakeWhile Xs Pred}
      case Xs
      of nil then nil
      [] H | T then
         if {Pred H} then
            H | {TakeWhile T Pred}
         else
            nil
         end
      end
   end

   % --------------------------------------------------------------------------
   % DropWhile: Drops leading elements satisfying Pred
   % --------------------------------------------------------------------------
   fun {DropWhile Xs Pred}
      case Xs
      of nil then nil
      [] H | T then
         if {Pred H} then
            {DropWhile T Pred}
         else
            Xs
         end
      end
   end

   % --------------------------------------------------------------------------
   % Zip: Combines two lists into list of pairs pair(X, Y)
   % --------------------------------------------------------------------------
   fun {Zip Xs Ys}
      case Xs # Ys
      of (X | Xr) # (Y | Yr) then
         pair(X Y) | {Zip Xr Yr}
      else
         nil
      end
   end

   % --------------------------------------------------------------------------
   % ZipWith: Combines two lists pairwise using binary function F
   % --------------------------------------------------------------------------
   fun {ZipWith Xs Ys F}
      case Xs # Ys
      of (X | Xr) # (Y | Yr) then
         {F X Y} | {ZipWith Xr Yr F}
      else
         nil
      end
   end

   % --------------------------------------------------------------------------
   % Unzip: Separates list of pairs into pair(Xs, Ys)
   % --------------------------------------------------------------------------
   fun {Unzip Pairs}
      case Pairs
      of nil then pair(nil nil)
      [] pair(X Y) | Rest then
         case {Unzip Rest}
         of pair(Xs Ys) then
            pair(X | Xs Y | Ys)
         end
      end
   end

   % --------------------------------------------------------------------------
   % Partition: Splits list into pair(Satisfying, Failing) based on Pred
   % --------------------------------------------------------------------------
   fun {Partition Xs Pred}
      case Xs
      of nil then pair(nil nil)
      [] H | T then
         case {Partition T Pred}
         of pair(Pass Fail) then
            if {Pred H} then
               pair(H | Pass Fail)
            else
               pair(Pass H | Fail)
            end
         end
      end
   end

   % --------------------------------------------------------------------------
   % GroupBy: Groups consecutive elements sharing the same key KeyFn(X)
   % --------------------------------------------------------------------------
   fun {GroupBy Xs KeyFn}
      case Xs
      of nil then nil
      [] H | T then
         Key = {KeyFn H}
         Matching = {TakeWhile T fun {$ X} {KeyFn X} == Key end}
         Remaining = {DropWhile T fun {$ X} {KeyFn X} == Key end}
         group(key: Key items: H | Matching) | {GroupBy Remaining KeyFn}
      end
   end

   % --------------------------------------------------------------------------
   % Intersperse: Injects separator element between list elements
   % --------------------------------------------------------------------------
   fun {Intersperse Xs Sep}
      case Xs
      of nil then nil
      [] H | nil then H | nil
      [] H | T then H | Sep | {Intersperse T Sep}
      end
   end

   % --------------------------------------------------------------------------
   % Flatten: Flattens list of lists into single list
   % --------------------------------------------------------------------------
   fun {Flatten Xss}
      case Xss
      of nil then nil
      [] Xs | Rest then
         case Xs
         of nil then {Flatten Rest}
         [] H | T then H | {Flatten T | Rest}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Dedup: Removes consecutive duplicate elements
   % --------------------------------------------------------------------------
   fun {Dedup Xs}
      case Xs
      of nil then nil
      [] H | nil then H | nil
      [] H1 | H2 | T then
         if H1 == H2 then
            {Dedup H2 | T}
         else
            H1 | {Dedup H2 | T}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Find: Returns opt(Value) for first element satisfying Pred, or none
   % --------------------------------------------------------------------------
   fun {Find Xs Pred}
      case Xs
      of nil then none
      [] H | T then
         if {Pred H} then
            opt(H)
         else
            {Find T Pred}
         end
      end
   end

   % --------------------------------------------------------------------------
   % FindIndex: Returns zero-based index of first element satisfying Pred, or ~1
   % --------------------------------------------------------------------------
   fun {FindIndex Xs Pred}
      fun {FindAux List Idx}
         case List
         of nil then ~1
         [] H | T then
            if {Pred H} then
               Idx
            else
               {FindAux T Idx + 1}
            end
         end
      end
   in
      {FindAux Xs 0}
   end

   % --------------------------------------------------------------------------
   % All: Universal quantifier over lists
   % --------------------------------------------------------------------------
   fun {All Xs Pred}
      case Xs
      of nil then true
      [] H | T then
         if {Pred H} then
            {All T Pred}
         else
            false
         end
      end
   end

   % --------------------------------------------------------------------------
   % Any: Existential quantifier over lists
   % --------------------------------------------------------------------------
   fun {Any Xs Pred}
      case Xs
      of nil then false
      [] H | T then
         if {Pred H} then
            true
         else
            {Any T Pred}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Chunk: Partitions list into chunks of length Size
   % --------------------------------------------------------------------------
   fun {Chunk Xs Size}
      if Xs == nil then
         nil
      else
         {Take Xs Size} | {Chunk {Drop Xs Size} Size}
      end
   end

   % --------------------------------------------------------------------------
   % Merge Sort with comparator Cmp(A, B) -> boolean (true if A <= B)
   % --------------------------------------------------------------------------
   fun {Merge Left Right Cmp}
      case Left # Right
      of nil # Ys then Ys
      [] Xs # nil then Xs
      [] (X | Xr) # (Y | Yr) then
         if {Cmp X Y} then
            X | {Merge Xr Right Cmp}
         else
            Y | {Merge Left Yr Cmp}
         end
      end
   end

   fun {SortWith Xs Cmp}
      case Xs
      of nil then nil
      [] _ | nil then Xs
      else
         Len = {Length Xs}
         Half = Len div 2
         case {SplitAt Xs Half}
         of pair(L R) then
            {Merge {SortWith L Cmp} {SortWith R Cmp} Cmp}
         end
      end
   end

end
