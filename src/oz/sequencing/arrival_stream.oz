% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.ArrivalStream
% Description: Arrival Manager (AMAN) stream sequencing, glideslope wake vortex
%              separation enforcement, and Target Landing Time (TLDT) allocation.
% =============================================================================

functor
import
   WakeMatrix at 'wake_matrix.oz'
   ListExt at '../core/list_ext.oz'
export
   SequenceArrivalStream: SequenceArrivalStream
   ComputeAirborneHoldingDelay: ComputeAirborneHoldingDelay
define

   % --------------------------------------------------------------------------
   % SequenceArrivalStream: Sequences arrival flights by earliest landing time (ELDT)
   % enforcing pairwise glideslope wake turbulence separation.
   % --------------------------------------------------------------------------
   fun {SequenceArrivalStream InboundFlights GlideslopeSpeedKnots}
      % Sort by estimated landing time
      Sorted = {ListExt.SortWith InboundFlights
                fun {$ A B} A.eldt =< B.eldt end}

      fun {AssignLandingSlots Flights LastLandingTime}
         case Flights
         of nil then nil
         [] F | Rest then
            SepSec = if LastLandingTime =< 0.0 then
                        0.0
                     else
                        % Determine leader's recat from previous slot
                        {WakeMatrix.GetSeparationTimeAtSpeed F.leadRecat F.recatCategory GlideslopeSpeedKnots}
                     end
            TargetLanding = if (LastLandingTime + SepSec) > F.eldt then
                               LastLandingTime + SepSec
                            else
                               F.eldt
                            end
            UpdatedFlight = arrival(callsign: F.callsign
                                    recatCategory: F.recatCategory
                                    eldt: F.eldt
                                    tldt: TargetLanding
                                    leadRecat: F.leadRecat
                                    assignedRunway: F.assignedRunway)
         in
            UpdatedFlight | {AssignLandingSlots Rest TargetLanding}
         end
      end
   in
      {AssignLandingSlots Sorted 0.0}
   end

   % --------------------------------------------------------------------------
   % Compute Airborne Delay: Difference between TLDT and ELDT
   % --------------------------------------------------------------------------
   fun {ComputeAirborneHoldingDelay ArrivalRecord}
      Delay = ArrivalRecord.tldt - ArrivalRecord.eldt
   in
      if Delay < 0.0 then 0.0 else Delay end
   end

end
