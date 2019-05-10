% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.PriorityQueue
% Description: Purely functional Leftist Min-Heap priority queue with O(log N)
%              insert and extract-min for A* routing and discrete event simulation.
% =============================================================================

functor
import
   System
export
   New: New
   Insert: Insert
   ExtractMin: ExtractMin
   FindMin: FindMin
   IsEmpty: IsEmpty
   Merge: Merge
   FromList: FromList
   ToList: ToList
define

   % --------------------------------------------------------------------------
   % Leftist Heap Representation:
   % empty
   % heap(rank: S prio: P val: V left: L right: R)
   % Invariant: Rank(L) >= Rank(R) and Prio <= Children
   % --------------------------------------------------------------------------

   fun {New}
      empty
   end

   fun {IsEmpty H}
      H == empty
   end

   fun {Rank H}
      case H
      of empty then 0
      [] heap(rank: S ...) then S
      end
   end

   fun {MakeHeap Prio Val L R}
      RankL = {Rank L}
      RankR = {Rank R}
   in
      if RankL >= RankR then
         heap(rank: RankR + 1 prio: Prio val: Val left: L right: R)
      else
         heap(rank: RankL + 1 prio: Prio val: Val left: R right: L)
      end
   end

   % --------------------------------------------------------------------------
   % Merge: Combines two leftist heaps in O(log N)
   % --------------------------------------------------------------------------
   fun {Merge H1 H2}
      case H1 # H2
      of empty # H then H
      [] H # empty then H
      [] heap(prio: P1 val: V1 left: L1 right: R1 ...) # heap(prio: P2 val: V2 left: L2 right: R2 ...) then
         if P1 =< P2 then
            {MakeHeap P1 V1 L1 {Merge R1 H2}}
         else
            {MakeHeap P2 V2 L2 {Merge H1 R2}}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Insert: Inserts priority-value pair into the heap
   % --------------------------------------------------------------------------
   fun {Insert H Prio Val}
      Single = heap(rank: 1 prio: Prio val: Val left: empty right: empty)
   in
      {Merge H Single}
   end

   % --------------------------------------------------------------------------
   % FindMin: Inspects minimum element without removing it
   % Returns opt(pair(Prio, Val)) or none
   % --------------------------------------------------------------------------
   fun {FindMin H}
      case H
      of empty then none
      [] heap(prio: P val: V ...) then
         opt(pair(P V))
      end
   end

   % --------------------------------------------------------------------------
   % ExtractMin: Removes root minimum element.
   % Returns pair(opt(pair(Prio, Val)), NewHeap)
   % --------------------------------------------------------------------------
   fun {ExtractMin H}
      case H
      of empty then
         pair(none empty)
      [] heap(prio: P val: V left: L right: R ...) then
         NewHeap = {Merge L R}
      in
         pair(opt(pair(P V)) NewHeap)
      end
   end

   % --------------------------------------------------------------------------
   % Conversions
   % --------------------------------------------------------------------------
   fun {FromList Pairs}
      fun {Build List H}
         case List
         of nil then H
         [] pair(P V) | Rest then
            {Build Rest {Insert H P V}}
         end
      end
   in
      {Build Pairs {New}}
   end

   fun {ToList H}
      case {ExtractMin H}
      of pair(none _) then nil
      [] pair(opt(Item) NextH) then
         Item | {ToList NextH}
      end
   end

end
