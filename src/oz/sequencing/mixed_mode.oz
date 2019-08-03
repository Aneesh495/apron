% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.MixedMode
% Description: Mixed-mode runway scheduling interleaving departure roll operations
%              into arrival landing intervals based on runway occupancy times (ROT).
% =============================================================================

functor
export
   ScheduleMixedMode: ScheduleMixedMode
   CanInsertDepartureInGap: CanInsertDepartureInGap
define

   % --------------------------------------------------------------------------
   % CanInsertDepartureInGap: Verifies whether time gap between arrivals Arr1 and Arr2
   % is sufficient to clear a departure roll.
   % Gap = (Arr2.tldt - Arr1.tldt) >= ROT(Arr1) + LineupTime + TakeoffRoll + SafetyBuffer
   % --------------------------------------------------------------------------
   fun {CanInsertDepartureInGap Arr1 Arr2 DepRotSec LineupSec BufferSec}
      ArrivalGap = Arr2.tldt - Arr1.tldt
      RequiredWindow = Arr1.rot + LineupSec + DepRotSec + BufferSec
   in
      ArrivalGap >= RequiredWindow
   end

   % --------------------------------------------------------------------------
   % ScheduleMixedMode: Interleaves departures into arrival stream
   % --------------------------------------------------------------------------
   fun {ScheduleMixedMode Arrivals Departures LineupSec BufferSec}
      fun {MergeStreams Arrs Deps CurrentTime}
         case Arrs # Deps
         of nil # nil then nil
         [] nil # (D | Dr) then
            % No more arrivals, schedule remaining departures consecutively
            TargetRoll = if CurrentTime < (D.tobt + D.exot) then (D.tobt + D.exot) else CurrentTime end
            ScheduledDep = mixed_event(type: departure
                                       callsign: D.callsign
                                       time: TargetRoll)
         in
            ScheduledDep | {MergeStreams nil Dr TargetRoll + 90.0}
         [] (A | Ar) # nil then
            % No more departures, schedule remaining arrivals
            ScheduledArr = mixed_event(type: arrival
                                       callsign: A.callsign
                                       time: A.tldt)
         in
            ScheduledArr | {MergeStreams Ar nil A.tldt + A.rot}
         [] (A1 | A2 | ArRest) # (D | Dr) then
            % Both available, test if departure can fit between A1 and A2
            EarliestDep = D.tobt + D.exot
            DepSlotCandidate = A1.tldt + A1.rot + LineupSec
            CanFit = {CanInsertDepartureInGap A1 A2 45.0 LineupSec BufferSec} andthen (DepSlotCandidate >= EarliestDep)
         in
            if CanFit then
               ScheduledA1 = mixed_event(type: arrival callsign: A1.callsign time: A1.tldt)
               ScheduledD  = mixed_event(type: departure callsign: D.callsign time: DepSlotCandidate)
            in
               ScheduledA1 | ScheduledD | {MergeStreams A2 | ArRest Dr DepSlotCandidate + 45.0}
            else
               ScheduledA1 = mixed_event(type: arrival callsign: A1.callsign time: A1.tldt)
            in
               ScheduledA1 | {MergeStreams A2 | ArRest Deps A1.tldt + A1.rot}
            end
         [] (A | nil) # (D | Dr) then
            ScheduledA = mixed_event(type: arrival callsign: A.callsign time: A.tldt)
         in
            ScheduledA | {MergeStreams nil Deps A.tldt + A.rot}
         end
      end
   in
      {MergeStreams Arrivals Departures 0.0}
   end

end
