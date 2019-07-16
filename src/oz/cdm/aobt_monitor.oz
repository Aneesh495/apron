% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.AOBTMonitor
% Description: Actual Off-Block Time (AOBT) pushback departure monitoring,
%              TSAT adherence auditing, and automated departure re-sequencing triggers.
% =============================================================================

functor
export
   ProcessActualPushback: ProcessActualPushback
   ComputePushbackAdherenceDelta: ComputePushbackAdherenceDelta
   RequiresResequencing: RequiresResequencing
define

   % --------------------------------------------------------------------------
   % ProcessActualPushback: Records actual off-block event and updates flight
   % --------------------------------------------------------------------------
   fun {ProcessActualPushback Flight ActualTime}
      flight(callsign: Flight.callsign
             gufi: Flight.gufi
             aircraftType: Flight.aircraftType
             recatCategory: Flight.recatCategory
             origin: Flight.origin
             destination: Flight.destination
             assignedStand: Flight.assignedStand
             assignedRunway: Flight.assignedRunway
             sidRoute: Flight.sidRoute
             sobt: Flight.sobt
             tobt: Flight.tobt
             tsat: Flight.tsat
             ttot: Flight.ttot
             aibt: Flight.aibt
             aobt: ActualTime
             atot: Flight.atot
             status: status_off_block)
   end

   % --------------------------------------------------------------------------
   % Pushback Adherence Delta: Positive if pushed late relative to TSAT
   % --------------------------------------------------------------------------
   fun {ComputePushbackAdherenceDelta AOBT TSAT}
      AOBT - TSAT
   end

   % --------------------------------------------------------------------------
   % Resequencing Trigger: Pushback delay > 180 seconds invalidates runway slot
   % --------------------------------------------------------------------------
   fun {RequiresResequencing AOBT TSAT ThresholdSec}
      Delta = {ComputePushbackAdherenceDelta AOBT TSAT}
   in
      Delta > ThresholdSec
   end

end
