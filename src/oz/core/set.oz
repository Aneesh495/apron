% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.Set
% Description: Purely functional finite set operations (Union, Intersection,
%              Difference, Subset) based on balanced binary search trees.
% =============================================================================

functor
import
   System
export
   New: New
   Insert: Insert
   Remove: Remove
   Member: Member
   Union: Union
   Intersection: Intersection
   Difference: Difference
   IsSubset: IsSubset
   IsEmpty: IsEmpty
   Size: Size
   ToList: ToList
   FromList: FromList
define

   % --------------------------------------------------------------------------
   % Set Representation:
   % empty
   % node(elem: E left: L right: R height: H)
   % --------------------------------------------------------------------------

   fun {New}
      empty
   end

   fun {IsEmpty S}
      S == empty
   end

   fun {Height S}
      case S
      of empty then 0
      [] node(height: H ...) then H
      end
   end

   fun {Max A B}
      if A > B then A else B end
   end

   fun {MakeNode E L R}
      H = 1 + {Max {Height L} {Height R}}
   in
      node(elem: E left: L right: R height: H)
   end

   fun {BalanceFactor S}
      case S
      of empty then 0
      [] node(left: L right: R ...) then
         {Height L} - {Height R}
      end
   end

   fun {RotateRight Y}
      case Y
      of node(elem: YE left: X right: T3 ...) then
         case X
         of node(elem: XE left: T1 right: T2 ...) then
            NewY = {MakeNode YE T2 T3}
         in
            {MakeNode XE T1 NewY}
         end
      end
   end

   fun {RotateLeft X}
      case X
      of node(elem: XE left: T1 right: Y ...) then
         case Y
         of node(elem: YE left: T2 right: T3 ...) then
            NewX = {MakeNode XE T1 T2}
         in
            {MakeNode YE NewX T3}
         end
      end
   end

   fun {Rebalance S}
      case S
      of empty then empty
      [] node(left: L right: R ...) then
         BF = {BalanceFactor S}
      in
         if BF > 1 then
            if {BalanceFactor L} >= 0 then
               {RotateRight S}
            else
               RotL = {RotateLeft L}
               NewS = {MakeNode S.elem RotL R}
            in
               {RotateRight NewS}
            end
         elseif BF < ~1 then
            if {BalanceFactor R} =< 0 then
               {RotateLeft S}
            else
               RotR = {RotateRight R}
               NewS = {MakeNode S.elem L RotR}
            in
               {RotateLeft NewS}
            end
         else
            S
         end
      end
   end

   % --------------------------------------------------------------------------
   % Membership Test
   % --------------------------------------------------------------------------
   fun {Member S Elem}
      case S
      of empty then false
      [] node(elem: E left: L right: R ...) then
         if Elem == E then
            true
         elseif Elem < E then
            {Member L Elem}
         else
            {Member R Elem}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Insertion
   % --------------------------------------------------------------------------
   fun {Insert S Elem}
      case S
      of empty then
         {MakeNode Elem empty empty}
      [] node(elem: E left: L right: R ...) then
         if Elem == E then
            S
         elseif Elem < E then
            {Rebalance {MakeNode E {Insert L Elem} R}}
         else
            {Rebalance {MakeNode E L {Insert R Elem}}}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Deletion
   % --------------------------------------------------------------------------
   fun {MinElem S}
      case S
      of node(left: empty elem: E ...) then E
      [] node(left: L ...) then {MinElem L}
      end
   end

   fun {Remove S Elem}
      case S
      of empty then empty
      [] node(elem: E left: L right: R ...) then
         if Elem < E then
            {Rebalance {MakeNode E {Remove L Elem} R}}
         elseif Elem > E then
            {Rebalance {MakeNode E L {Remove R Elem}}}
         else
            if L == empty then R
            elseif R == empty then L
            else
               MinE = {MinElem R}
               NewR = {Remove R MinE}
            in
               {Rebalance {MakeNode MinE L NewR}}
            end
         end
      end
   end

   % --------------------------------------------------------------------------
   % Set Cardinality and Elements
   % --------------------------------------------------------------------------
   fun {Size S}
      case S
      of empty then 0
      [] node(left: L right: R ...) then
         1 + {Size L} + {Size R}
      end
   end

   fun {ToList S}
      case S
      of empty then nil
      [] node(elem: E left: L right: R ...) then
         {Append {ToList L} E | {ToList R}}
      end
   end

   fun {FromList Xs}
      fun {Build List S}
         case List
         of nil then S
         [] H | T then {Build T {Insert S H}}
         end
      end
   in
      {Build Xs {New}}
   end

   % --------------------------------------------------------------------------
   % Set Algebraic Operations
   % --------------------------------------------------------------------------
   fun {Union S1 S2}
      L2 = {ToList S2}
      fun {AddElements List S}
         case List
         of nil then S
         [] H | T then {AddElements T {Insert S H}}
         end
      end
   in
      {AddElements L2 S1}
   end

   fun {Intersection S1 S2}
      L1 = {ToList S1}
      fun {KeepCommon List Acc}
         case List
         of nil then Acc
         [] H | T then
            if {Member S2 H} then
               {KeepCommon T {Insert Acc H}}
            else
               {KeepCommon T Acc}
            end
         end
      end
   in
      {KeepCommon L1 {New}}
   end

   fun {Difference S1 S2}
      L1 = {ToList S1}
      fun {RemoveCommon List Acc}
         case List
         of nil then Acc
         [] H | T then
            if {Member S2 H} then
               {RemoveCommon T Acc}
            else
               {RemoveCommon T {Insert Acc H}}
            end
         end
      end
   in
      {RemoveCommon L1 {New}}
   end

   fun {IsSubset S1 S2}
      L1 = {ToList S1}
      fun {CheckSub List}
         case List
         of nil then true
         [] H | T then
            if {Member S2 H} then
               {CheckSub T}
            else
               false
            end
         end
      end
   in
      {CheckSub L1}
   end

end
