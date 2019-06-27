% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.TSAT
% Description: Target Startup Approval Time (TSAT) derivation, departure metering,
%              gate-hold delay smoothing, and sequence freeze horizon logic.
% =============================================================================

functor
export
   ComputeTSAT: ComputeTSAT
   IsWithinStartupWindow: IsWithinStartupWindow
   SequenceTSATQueue: SequenceTSATQueue
   IsSequenceFrozen: IsSequenceFrozen
define

   % --------------------------------------------------------------------------
   % ComputeTSAT: Calculates TSAT = max(TOBT, TTOT - EXOT)
   % --------------------------------------------------------------------------
   fun {ComputeTSAT TOBT TTOT EXOT}
      EarliestStartup = TTOT - EXOT
   in
      if EarliestStartup < TOBT then
         TOBT
      else
         EarliestStartup
      end
   end

   % --------------------------------------------------------------------------
   % Check whether flight is within permissible startup window [TSAT - 5, TSAT + 5] min
   % --------------------------------------------------------------------------
   fun {IsWithinStartupWindow RequestTime TSAT}
      Diff = RequestTime - TSAT
   in
      Diff >= ~300.0 andthen Diff =< 300.0
   end

   % --------------------------------------------------------------------------
   % Freeze Horizon: Sequences within 30 minutes of TSAT are locked
   % --------------------------------------------------------------------------
   fun {IsSequenceFrozen CurrentTime TSAT FreezeHorizonSec}
      (TSAT - CurrentTime) =< FreezeHorizonSec
   end

   % --------------------------------------------------------------------------
   % SequenceTSATQueue: Assigns non-conflicting TSATs across candidate flights
   % Ensures minimum pushback spacing on apron taxiways (e.g. 120 seconds)
   % --------------------------------------------------------------------------
   fun {SequenceTSATQueue Flights MinPushbackSpacingSec}
      fun {ScheduleFlights List LastTSAT}
         case List
         of nil then nil
         [] F | Rest then
            ProposedTSAT = {ComputeTSAT F.tobt F.ttot 600.0} % 10 min nominal EXOT
            AssignedTSAT = if ProposedTSAT < (LastTSAT + MinPushbackSpacingSec) then
                              LastTSAT + MinPushbackSpacingSec
                           else
                              ProposedTSAT
                           end
            UpdatedFlight = flight(callsign: F.callsign
                                   gufi: F.gufi
                                   aircraftType: F.aircraftType
                                   recatCategory: F.recatCategory
                                   origin: F.origin
                                   destination: F.destination
                                   assignedStand: F.assignedStand
                                   assignedRunway: F.assignedRunway
                                   sidRoute: F.sidRoute
                                   sobt: F.sobt
                                   tobt: F.tobt
                                   tsat: AssignedTSAT
                                   ttot: F.ttot
                                   aibt: F.aibt
                                   aobt: F.aobt
                                   atot: F.atot
                                   status: F.status)
         in
            UpdatedFlight | {ScheduleFlights Rest AssignedTSAT}
         end
      end
   in
      {ScheduleFlights Flights 0.0}
   end

end
