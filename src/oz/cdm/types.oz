% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.Types
% Description: A-CDM milestone enumerations, flight turnaround lifecycle states,
%              and operational timestamps according to Eurocontrol Doc 9829.
% =============================================================================

functor
export
   % Lifecycle Status
   STATUS_SCHEDULED: STATUS_SCHEDULED
   STATUS_AIRBORNE: STATUS_AIRBORNE
   STATUS_LANDED: STATUS_LANDED
   STATUS_IN_BLOCK: STATUS_IN_BLOCK
   STATUS_TURNAROUND: STATUS_TURNAROUND
   STATUS_BOARDING: STATUS_BOARDING
   STATUS_STARTUP_REQUESTED: STATUS_STARTUP_REQUESTED
   STATUS_STARTUP_APPROVED: STATUS_STARTUP_APPROVED
   STATUS_OFF_BLOCK: STATUS_OFF_BLOCK
   STATUS_TAXIING: STATUS_TAXIING
   STATUS_DEPARTED: STATUS_DEPARTED
   STATUS_CANCELLED: STATUS_CANCELLED

   % Flight Constructor
   NewFlightRecord: NewFlightRecord
define

   STATUS_SCHEDULED         = status_scheduled
   STATUS_AIRBORNE          = status_airborne
   STATUS_LANDED            = status_landed
   STATUS_IN_BLOCK          = status_in_block
   STATUS_TURNAROUND        = status_turnaround
   STATUS_BOARDING          = status_boarding
   STATUS_STARTUP_REQUESTED = status_startup_requested
   STATUS_STARTUP_APPROVED  = status_startup_approved
   STATUS_OFF_BLOCK         = status_off_block
   STATUS_TAXIING           = status_taxiing
   STATUS_DEPARTED          = status_departed
   STATUS_CANCELLED         = status_cancelled

   % --------------------------------------------------------------------------
   % Flight Record Constructor:
   % flight(callsign: String
   %        gufi: String
   %        aircraftType: String
   %        recatCategory: CategoryAtom  % cat_a .. cat_f
   %        origin: String
   %        destination: String
   %        assignedStand: String
   %        assignedRunway: String
   %        sidRoute: String
   %        sobt: Float
   %        tobt: Float
   %        tsat: Float
   %        ttot: Float
   %        aibt: Float
   %        aobt: Float
   %        atot: Float
   %        status: StatusAtom)
   % --------------------------------------------------------------------------

   fun {NewFlightRecord Callsign Gufi AcType Recat Orig Dest Stand Rwy Sid Sobt Tobt}
      flight(callsign: Callsign
             gufi: Gufi
             aircraftType: AcType
             recatCategory: Recat
             origin: Orig
             destination: Dest
             assignedStand: Stand
             assignedRunway: Rwy
             sidRoute: Sid
             sobt: Sobt
             tobt: Tobt
             tsat: ~1.0
             ttot: ~1.0
             aibt: ~1.0
             aobt: ~1.0
             atot: ~1.0
             status: STATUS_SCHEDULED)
   end

end
