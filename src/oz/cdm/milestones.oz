% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.Milestones
% Description: The 16 ICAO Doc 9829 / Eurocontrol turnaround milestone event processor,
%              validation predicates, and chronological progression assertions.
% =============================================================================

functor
import
   Types at 'types.oz'
   System
export
   AdvanceMilestone: AdvanceMilestone
   GetMilestoneName: GetMilestoneName
   ValidateMilestoneSequence: ValidateMilestoneSequence
define

   fun {GetMilestoneName MIndex}
      case MIndex
      of 1 then "M1: Inbound Flight Plan Activated (IFPA)"
      [] 2 then "M2: Inbound FIR / TMA Entry"
      [] 3 then "M3: Inbound Touchdown (ALDT)"
      [] 4 then "M4: Inbound In-Block at Stand (AIBT)"
      [] 5 then "M5: Ground Turnaround Commenced"
      [] 6 then "M6: Initial TOBT Published"
      [] 7 then "M7: Turnaround Progress Check -40 min"
      [] 8 then "M8: Turnaround Progress Check -20 min"
      [] 9 then "M9: Passenger Boarding Commenced"
      [] 10 then "M10: TSAT Issued by Sequencer"
      [] 11 then "M11: Boarding Completed / Doors Closed"
      [] 12 then "M12: Startup / Pushback Requested"
      [] 13 then "M13: Startup / Pushback Approved (ASAT)"
      [] 14 then "M14: Actual Off-Block Initiation (AOBT)"
      [] 15 then "M15: Taxi-Out Commenced (EXOT)"
      [] 16 then "M16: Actual Take-Off Roll (ATOT)"
      else "Unknown Milestone"
      end
   end

   % --------------------------------------------------------------------------
   % State Machine Transition Function
   % Advances flight through milestone MIndex with event timestamp EventTime
   % --------------------------------------------------------------------------
   fun {AdvanceMilestone Flight MIndex EventTime}
      case MIndex
      of 3 then
         % Landing Touchdown ALDT
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
                aobt: Flight.aobt
                atot: Flight.atot
                status: Types.STATUS_LANDED)

      [] 4 then
         % In-Block AIBT
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
                aibt: EventTime
                aobt: Flight.aobt
                atot: Flight.atot
                status: Types.STATUS_IN_BLOCK)

      [] 9 then
         % Boarding commenced
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
                aobt: Flight.aobt
                atot: Flight.atot
                status: Types.STATUS_BOARDING)

      [] 12 then
         % Startup Requested
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
                aobt: Flight.aobt
                atot: Flight.atot
                status: Types.STATUS_STARTUP_REQUESTED)

      [] 13 then
         % Startup Approved
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
                aobt: Flight.aobt
                atot: Flight.atot
                status: Types.STATUS_STARTUP_APPROVED)

      [] 14 then
         % Actual Off-Block (AOBT)
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
                aobt: EventTime
                atot: Flight.atot
                status: Types.STATUS_OFF_BLOCK)

      [] 16 then
         % Actual Take-Off (ATOT)
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
                aobt: Flight.aobt
                atot: EventTime
                status: Types.STATUS_DEPARTED)

      else
         Flight
      end
   end

   % --------------------------------------------------------------------------
   % Validates chronological order of timestamps
   % --------------------------------------------------------------------------
   fun {ValidateMilestoneSequence MilestoneTimes}
      fun {CheckAscending Times LastTime}
         case Times
         of nil then true
         [] T | Rest then
            if T >= LastTime then
               {CheckAscending Rest T}
            else
               false
            end
         end
      end
   in
      case MilestoneTimes
      of nil then true
      [] First | Rest then {CheckAscending Rest First}
      end
   end

end
