% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.Coordination
% Description: Multi-stakeholder collaborative negotiation protocol reconciling
%              Airline (AOC), Ground Handler, Apron Control, and Tower constraints.
% =============================================================================

functor
import
   System
   TOBT at 'tobt.oz'
   TSAT at 'tsat.oz'
   DPI at 'dpi.oz'
export
   HandleHandlerTOBTUpdate: HandleHandlerTOBTUpdate
   HandleATCPreSequence: HandleATCPreSequence
   HandleCockpitPushbackRequest: HandleCockpitPushbackRequest
define

   % --------------------------------------------------------------------------
   % HandleHandlerTOBTUpdate: Stakeholder entry point for Ground Handlers
   % Validates new TOBT, triggers T-DPI if threshold exceeded, and notifies DMAN
   % --------------------------------------------------------------------------
   fun {HandleHandlerTOBTUpdate Flight NewTOBT CurrentTime MinTurnaroundSec}
      case {TOBT.ValidateTOBT NewTOBT Flight.aibt CurrentTime MinTurnaroundSec}
      of pair(true _) then
         ShouldDpi = {TOBT.ShouldEmitTargetDPI Flight.tobt NewTOBT}
         UpdatedFlight = flight(callsign: Flight.callsign
                                gufi: Flight.gufi
                                aircraftType: Flight.aircraftType
                                recatCategory: Flight.recatCategory
                                origin: Flight.origin
                                destination: Flight.destination
                                assignedStand: Flight.assignedStand
                                assignedRunway: Flight.assignedRunway
                                sidRoute: Flight.sidRoute
                                sobt: Flight.sobt
                                tobt: NewTOBT
                                tsat: Flight.tsat
                                ttot: Flight.ttot
                                aibt: Flight.aibt
                                aobt: Flight.aobt
                                atot: Flight.atot
                                status: Flight.status)
         DpiMessage = if ShouldDpi then
                         opt({DPI.CreateDPI DPI.DPI_TARGET UpdatedFlight CurrentTime})
                      else
                         none
                      end
      in
         response(status: ok flight: UpdatedFlight dpi: DpiMessage)
      [] pair(false Reason) then
         response(status: rejected reason: Reason flight: Flight dpi: none)
      end
   end

   % --------------------------------------------------------------------------
   % HandleATCPreSequence: ATC DMAN locks sequence and issues initial TSAT/A-DPI
   % --------------------------------------------------------------------------
   fun {HandleATCPreSequence Flight SequencedTSAT SequencedTTOT CurrentTime}
      UpdatedFlight = flight(callsign: Flight.callsign
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
                             tsat: SequencedTSAT
                             ttot: SequencedTTOT
                             aibt: Flight.aibt
                             aobt: Flight.aobt
                             atot: Flight.atot
                             status: Flight.status)
      Adpi = {DPI.CreateDPI DPI.DPI_ATC_PRE UpdatedFlight CurrentTime}
   in
      response(status: ok flight: UpdatedFlight dpi: opt(Adpi))
   end

   % --------------------------------------------------------------------------
   % HandleCockpitPushbackRequest: Flight crew calls Apron Control on radio
   % Verifies flight is within TSAT startup approval window
   % --------------------------------------------------------------------------
   fun {HandleCockpitPushbackRequest Flight RequestTime ApronClearanceAvailable}
      IsWindowOk = {TSAT.IsWithinStartupWindow RequestTime Flight.tsat}
   in
      if IsWindowOk == false then
         response(status: hold_position
                  reason: outside_tsat_window
                  flight: Flight)
      elseif ApronClearanceAvailable == false then
         response(status: hold_position
                  reason: apron_lane_blocked
                  flight: Flight)
      else
         UpdatedFlight = flight(callsign: Flight.callsign
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
                                aobt: Flight.aobt
                                atot: Flight.atot
                                status: status_startup_approved)
      in
         response(status: pushback_approved
                  reason: cleared_as_filed
                  flight: UpdatedFlight)
      end
   end

end
