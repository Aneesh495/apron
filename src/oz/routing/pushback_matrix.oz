% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.PushbackMatrix
% Description: Cul-de-sac alleyway topological analysis, pushback blocking matrices,
%              and apron taxilane contention avoidance algorithms.
% =============================================================================

functor
export
   BuildCulDeSacMatrix: BuildCulDeSacMatrix
   AreStandsMutuallyExclusive: AreStandsMutuallyExclusive
   GetAlleywayBlockingWindow: GetAlleywayBlockingWindow
define

   % --------------------------------------------------------------------------
   % Cul-de-Sac Definition:
   % culdesac(id: Id entryNodeId: Id standIds: ListOfStandIds)
   % --------------------------------------------------------------------------

   fun {BuildCulDeSacMatrix CulDeSacs}
      fun {ProcessCds List MatrixAcc}
         case List
         of nil then MatrixAcc
         [] CDS | Rest then
            Stands = CDS.standIds
            fun {PairAll SList}
               case SList
               of nil then nil
               [] S1 | Sr then
                  fun {WithRest S2List}
                     case S2List
                     of nil then nil
                     [] S2 | S2r then
                        pair(S1 S2) | pair(S2 S1) | {WithRest S2r}
                     end
                  end
               in
                  {Append {WithRest Sr} {PairAll Sr}}
               end
            end
            BlockingPairs = {PairAll Stands}
         in
            {ProcessCds Rest {Append BlockingPairs MatrixAcc}}
         end
      end
   in
      {ProcessCds CulDeSacs nil}
   end

   % --------------------------------------------------------------------------
   % AreStandsMutuallyExclusive: Returns true if Stand1 and Stand2 share a cul-de-sac
   % preventing simultaneous pushback operations.
   % --------------------------------------------------------------------------
   fun {AreStandsMutuallyExclusive StandId1 StandId2 BlockingMatrix}
      fun {CheckPairs List}
         case List
         of nil then false
         [] pair(S1 S2) | Rest then
            if S1 == StandId1 andthen S2 == StandId2 then
               true
            else
               {CheckPairs Rest}
            end
         end
      end
   in
      if StandId1 == StandId2 then true else {CheckPairs BlockingMatrix} end
   end

   % --------------------------------------------------------------------------
   % Alleyway Blocking Window: Duration pushback maneuver locks the taxilane
   % --------------------------------------------------------------------------
   fun {GetAlleywayBlockingWindow AircraftCode}
      case AircraftCode
      of cat_a then 300.0  % 5 minutes for A380 push and tow-bar disconnect
      [] cat_b then 240.0  % 4 minutes for B777
      [] cat_c then 210.0  % 3.5 minutes for B787
      [] cat_d then 180.0  % 3 minutes for A320
      else 150.0
      end
   end

end
