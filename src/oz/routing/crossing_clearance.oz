% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.CrossingClearance
% Description: Active runway crossing clearance protocol, safety interlocking,
%              gap acceptance verification, and automatic stopbar coordination.
% =============================================================================

functor
export
   RequestRunwayCrossing: RequestRunwayCrossing
   IsCrossingGapAcceptable: IsCrossingGapAcceptable
   CompleteRunwayCrossing: CompleteRunwayCrossing
define

   % --------------------------------------------------------------------------
   % IsCrossingGapAcceptable: Evaluates if time to next arrival or departure
   % is greater than required crossing duration plus safety buffer.
   % --------------------------------------------------------------------------
   fun {IsCrossingGapAcceptable TimeToNextMovement CrossingDurationSec SafetyBufferSec}
      TimeToNextMovement >= (CrossingDurationSec + SafetyBufferSec)
   end

   % --------------------------------------------------------------------------
   % RequestRunwayCrossing: Tower crossing coordinator
   % Returns pair(GrantedBoolean, ClearanceRecord)
   % --------------------------------------------------------------------------
   fun {RequestRunwayCrossing CrossingId FlightId RunwayId NextMovementTime CurrentTime CrossingDurationSec}
      TimeToMovement = NextMovementTime - CurrentTime
      IsSafe = {IsCrossingGapAcceptable TimeToMovement CrossingDurationSec 45.0} % 45s safety buffer
   in
      if IsSafe then
         Clearance = clearance(crossingId: CrossingId
                               flightId: FlightId
                               runwayId: RunwayId
                               grantedAt: CurrentTime
                               clearedUntil: CurrentTime + CrossingDurationSec
                               status: active)
      in
         pair(true Clearance)
      else
         Clearance = clearance(crossingId: CrossingId
                               flightId: FlightId
                               runwayId: RunwayId
                               grantedAt: 0.0
                               clearedUntil: 0.0
                               status: hold_short)
      in
         pair(false Clearance)
      end
   end

   % --------------------------------------------------------------------------
   % CompleteRunwayCrossing: Aircraft sensor reports across far holding line
   % --------------------------------------------------------------------------
   fun {CompleteRunwayCrossing Clearance CompletionTime}
      clearance(crossingId: Clearance.crossingId
                flightId: Clearance.flightId
                runwayId: Clearance.runwayId
                grantedAt: Clearance.grantedAt
                clearedUntil: CompletionTime
                status: completed)
   end

end
