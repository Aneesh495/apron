% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Safety.Deadlocks
% Description: Surface deadlock detection (Wait-For-Graph cycles), taxiway gridlock
%              identification, and automated rollback resolution recommendations.
% =============================================================================

functor
export
   DetectWaitCycle: DetectWaitCycle
   RecommendDeadlockResolution: RecommendDeadlockResolution
define

   % --------------------------------------------------------------------------
   % DetectWaitCycle: Checks for circular dependency in wait-for graph:
   % pair(AircraftA AircraftB) where A is waiting on B and B is waiting on A
   % --------------------------------------------------------------------------
   fun {DetectWaitCycle WaitForEdges}
      fun {HasCycle Edges}
         case Edges
         of nil then false
         [] pair(A B) | Rest then
            fun {CheckOpposing List}
               case List
               of nil then false
               [] pair(X Y) | R2 then
                  if X == B andthen Y == A then true else {CheckOpposing R2} end
               end
            end
         in
            if {CheckOpposing Rest} then
               true
            else
               {HasCycle Rest}
            end
         end
      end
   in
      {HasCycle WaitForEdges}
   end

   % --------------------------------------------------------------------------
   % RecommendDeadlockResolution: Decides which aircraft to back up or divert
   % Prioritizes higher priority flights (e.g. emergency, international widebody)
   % --------------------------------------------------------------------------
   fun {RecommendDeadlockResolution AircraftA PriorityA AircraftB PriorityB StandbyBayNodeId}
      if PriorityA >= PriorityB then
         resolution(divertAircraft: AircraftB
                    holdingLocation: StandbyBayNodeId
                    passAircraft: AircraftA
                    action: "Instruct lower priority aircraft to enter standby holding bay")
      else
         resolution(divertAircraft: AircraftA
                    holdingLocation: StandbyBayNodeId
                    passAircraft: AircraftB
                    action: "Instruct lower priority aircraft to enter standby holding bay")
      end
   end

end
