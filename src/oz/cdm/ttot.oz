% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.TTOT
% Description: Target Take-Off Time (TTOT) derivation, Eurocontrol CTOT ATFCM
%              slot window compliance [-5, +10] min, and runway metering.
% =============================================================================

functor
export
   ComputeTTOT: ComputeTTOT
   IsCtotSlotCompliant: IsCtotSlotCompliant
   ComputeTakeOffDelay: ComputeTakeOffDelay
   IsRunwayHourlyCapacityExceeded: IsRunwayHourlyCapacityExceeded
define

   % --------------------------------------------------------------------------
   % ComputeTTOT: Derives expected runway departure roll initiation
   % TTOT = TSAT + EXOT + LineupBuffer
   % --------------------------------------------------------------------------
   fun {ComputeTTOT TSAT EXOT LineupBufferSec}
      TSAT + EXOT + LineupBufferSec
   end

   % --------------------------------------------------------------------------
   % Eurocontrol ATFCM Slot Compliance:
   % Window: [CTOT - 5 min, CTOT + 10 min] (-300s to +600s)
   % --------------------------------------------------------------------------
   fun {IsCtotSlotCompliant TTOT CTOT}
      if CTOT < 0.0 then
         true % No slot allocated (unrestricted flight)
      else
         Diff = TTOT - CTOT
      in
         Diff >= ~300.0 andthen Diff =< 600.0
      end
   end

   % --------------------------------------------------------------------------
   % Take-Off Schedule Delay: Deviation between TTOT and SOBT
   % --------------------------------------------------------------------------
   fun {ComputeTakeOffDelay TTOT SOBT EXOT}
      ScheduledTakeOff = SOBT + EXOT
      Delay = TTOT - ScheduledTakeOff
   in
      if Delay < 0.0 then 0.0 else Delay end
   end

   % --------------------------------------------------------------------------
   % Capacity Verification: Checks departure count against hourly ceiling
   % --------------------------------------------------------------------------
   fun {IsRunwayHourlyCapacityExceeded DeparturesInHour MaxMovementsPerHour}
      DeparturesInHour > MaxMovementsPerHour
   end

end
