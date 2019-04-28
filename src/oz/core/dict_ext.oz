% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.DictExt
% Description: Purely functional, persistent balanced AVL key-value dictionary
%              with O(log N) lookup, insertion, and deletion for airfield states.
% =============================================================================

functor
import
   System
export
   New: New
   Get: Get
   Put: Put
   Remove: Remove
   ContainsKey: ContainsKey
   Keys: Keys
   Values: Values
   Entries: Entries
   Fold: Fold
   MapValues: MapValues
   MergeWith: MergeWith
   IsEmpty: IsEmpty
   Size: Size
define

   % --------------------------------------------------------------------------
   % Node Representation:
   % empty
   % node(key: K val: V height: H left: L right: R)
   % --------------------------------------------------------------------------

   fun {New}
      empty
   end

   fun {IsEmpty Tree}
      Tree == empty
   end

   fun {Height Tree}
      case Tree
      of empty then 0
      [] node(height: H ...) then H
      end
   end

   fun {BalanceFactor Tree}
      case Tree
      of empty then 0
      [] node(left: L right: R ...) then
         {Height L} - {Height R}
      end
   end

   fun {Max A B}
      if A > B then A else B end
   end

   fun {MakeNode K V L R}
      H = 1 + {Max {Height L} {Height R}}
   in
      node(key: K val: V height: H left: L right: R)
   end

   % --------------------------------------------------------------------------
   % AVL Tree Rotations
   % --------------------------------------------------------------------------
   fun {RotateRight Y}
      case Y
      of node(key: YK val: YV left: X right: T3 ...) then
         case X
         of node(key: XK val: XV left: T1 right: T2 ...) then
            NewY = {MakeNode YK YV T2 T3}
         in
            {MakeNode XK XV T1 NewY}
         end
      end
   end

   fun {RotateLeft X}
      case X
      of node(key: XK val: XV left: T1 right: Y ...) then
         case Y
         of node(key: YK val: YV left: T2 right: T3 ...) then
            NewX = {MakeNode XK XV T1 T2}
         in
            {MakeNode YK YV NewX T3}
         end
      end
   end

   fun {Rebalance Tree}
      case Tree
      of empty then empty
      [] node(left: L right: R ...) then
         BF = {BalanceFactor Tree}
      in
         if BF > 1 then
            % Left Heavy
            if {BalanceFactor L} >= 0 then
               {RotateRight Tree}
            else
               % Left-Right Case
               RotL = {RotateLeft L}
               NewTree = {MakeNode Tree.key Tree.val RotL R}
            in
               {RotateRight NewTree}
            end
         elseif BF < ~1 then
            % Right Heavy
            if {BalanceFactor R} =< 0 then
               {RotateLeft Tree}
            else
               % Right-Left Case
               RotR = {RotateRight R}
               NewTree = {MakeNode Tree.key Tree.val L RotR}
            in
               {RotateLeft NewTree}
            end
         else
            Tree
         end
      end
   end

   % --------------------------------------------------------------------------
   % Lookup: Returns opt(Value) or none
   % --------------------------------------------------------------------------
   fun {Get Tree Key}
      case Tree
      of empty then none
      [] node(key: K val: V left: L right: R ...) then
         if Key == K then
            opt(V)
         elseif Key < K then
            {Get L Key}
         else
            {Get R Key}
         end
      end
   end

   fun {ContainsKey Tree Key}
      case {Get Tree Key}
      of opt(_) then true
      [] none then false
      end
   end

   % --------------------------------------------------------------------------
   % Insertion: Persistent O(log N) insert or update
   % --------------------------------------------------------------------------
   fun {Put Tree Key Val}
      case Tree
      of empty then
         {MakeNode Key Val empty empty}
      [] node(key: K val: V left: L right: R ...) then
         if Key == K then
            {MakeNode Key Val L R}
         elseif Key < K then
            {Rebalance {MakeNode K V {Put L Key Val} R}}
         else
            {Rebalance {MakeNode K V L {Put R Key Val}}}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Deletion: Persistent O(log N) removal
   % --------------------------------------------------------------------------
   fun {MinNode Tree}
      case Tree
      of node(left: empty ...) then Tree
      [] node(left: L ...) then {MinNode L}
      end
   end

   fun {Remove Tree Key}
      case Tree
      of empty then empty
      [] node(key: K val: V left: L right: R ...) then
         if Key < K then
            {Rebalance {MakeNode K V {Remove L Key} R}}
         elseif Key > K then
            {Rebalance {MakeNode K V L {Remove R Key}}}
         else
            % Key matches node to delete
            if L == empty then
               R
            elseif R == empty then
               L
            else
               MinSuccessor = {MinNode R}
               NewR = {Remove R MinSuccessor.key}
            in
               {Rebalance {MakeNode MinSuccessor.key MinSuccessor.val L NewR}}
            end
         end
      end
   end

   % --------------------------------------------------------------------------
   % In-Order Traversal Collectors
   % --------------------------------------------------------------------------
   fun {Entries Tree}
      case Tree
      of empty then nil
      [] node(key: K val: V left: L right: R ...) then
         {Append {Entries L} pair(K V) | {Entries R}}
      end
   end

   fun {Keys Tree}
      case Tree
      of empty then nil
      [] node(key: K left: L right: R ...) then
         {Append {Keys L} K | {Keys R}}
      end
   end

   fun {Values Tree}
      case Tree
      of empty then nil
      [] node(val: V left: L right: R ...) then
         {Append {Values L} V | {Values R}}
      end
   end

   fun {Size Tree}
      case Tree
      of empty then 0
      [] node(left: L right: R ...) then
         1 + {Size L} + {Size R}
      end
   end

   % --------------------------------------------------------------------------
   % Fold: In-order reduction over key-value pairs
   % --------------------------------------------------------------------------
   fun {Fold Tree F Acc}
      case Tree
      of empty then Acc
      [] node(key: K val: V left: L right: R ...) then
         Acc1 = {Fold L F Acc}
         Acc2 = {F K V Acc1}
      in
         {Fold R F Acc2}
      end
   end

   % --------------------------------------------------------------------------
   % Map: Applies F to all values, preserving tree keys and balance
   % --------------------------------------------------------------------------
   fun {MapValues Tree F}
      case Tree
      of empty then empty
      [] node(key: K val: V left: L right: R height: H) then
         node(key: K val: {F V} height: H left: {MapValues L F} right: {MapValues R F})
      end
   end

   % --------------------------------------------------------------------------
   % MergeWith: Merges DictB into DictA with collision resolver ResolveFn(Key, V1, V2)
   % --------------------------------------------------------------------------
   fun {MergeWith DictA DictB ResolveFn}
      {Fold DictB
         fun {$ K V2 CurrentTree}
            case {Get CurrentTree K}
            of none then
               {Put CurrentTree K V2}
            [] opt(V1) then
               ResolvedVal = {ResolveFn K V1 V2}
            in
               {Put CurrentTree K ResolvedVal}
            end
         end
         DictA}
   end

end
