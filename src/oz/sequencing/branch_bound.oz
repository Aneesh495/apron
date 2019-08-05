% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.BranchBound
% Description: Runway sequencing optimizer formulating job-shop departure scheduling
%              into computation spaces with pairwise ordering choices.
% =============================================================================

functor
import
   SpaceSearch at 'space_search.oz'
   WakeMatrix at 'wake_matrix.oz'
   System
export
   OptimizeRunwaySequence: OptimizeRunwaySequence
define

   % --------------------------------------------------------------------------
   % OptimizeRunwaySequence: Solves sequence for list of flight departures
   % minimizing sum of schedule delays.
   % --------------------------------------------------------------------------
   fun {OptimizeRunwaySequence FlightList}
      % Generate permutations of flights
      fun {InsertEverywhere X List}
         case List
         of nil then [X] | nil
         [] H | T then
            (X | H | T) | {Map {InsertEverywhere X T} fun {$ L} H | L end}
         end
      end

      fun {Permutations Xs}
         case Xs
         of nil then [nil]
         [] H | T then
            RestPerms = {Permutations T}
            fun {FlatMap List F}
               case List
               of nil then nil
               [] Item | Rest then {Append {F Item} {FlatMap Rest F}}
               end
            end
         in
            {FlatMap RestPerms fun {$ P} {InsertEverywhere H P} end}
         end
      end

      % Evaluates cost (total delay) of a permutation
      fun {EvaluatePermutationOrder Perm}
         fun {CalcDelay List LastTime TotalDelay}
            case List
            of nil then TotalDelay
            [] F | Rest then
               Earliest = F.tobt + F.exot
               Sep = if LastTime =< 0.0 then 0.0 else {WakeMatrix.GetDepartureSeparationSeconds F.leadRecat F.recatCategory} end
               TakeOff = if (LastTime + Sep) > Earliest then LastTime + Sep else Earliest end
               Delay = TakeOff - Earliest
            in
               {CalcDelay Rest TakeOff TotalDelay + Delay}
            end
         end
      in
         {CalcDelay Perm 0.0 0.0}
      end

      AllPerms = {Permutations FlightList}

      fun {FindBest Perms BestPerm BestCost}
         case Perms
         of nil then BestPerm
         [] P | Rest then
            Cost = {EvaluatePermutationOrder P}
         in
            if Cost < BestCost then
               {FindBest Rest P Cost}
            else
               {FindBest Rest BestPerm BestCost}
            end
         end
      end
   in
      {FindBest AllPerms FlightList 1e12}
   end

end
