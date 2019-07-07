% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.DPI
% Description: Eurocontrol Departure Planning Information (DPI) telex generator
%              (Early-DPI, Target-DPI, ATC-Pre-DPI, SIR-DPI, Cancel-DPI).
% =============================================================================

functor
export
   DPI_EARLY: DPI_EARLY
   DPI_TARGET: DPI_TARGET
   DPI_ATC_PRE: DPI_ATC_PRE
   DPI_SEQUENCED: DPI_SEQUENCED
   DPI_CANCEL: DPI_CANCEL
   CreateDPI: CreateDPI
   FormatDPITelex: FormatDPITelex
define

   DPI_EARLY     = dpi_early
   DPI_TARGET    = dpi_target
   DPI_ATC_PRE   = dpi_atc_pre
   DPI_SEQUENCED = dpi_sequenced
   DPI_CANCEL    = dpi_cancel

   % --------------------------------------------------------------------------
   % CreateDPI: Generates structured DPI message record
   % --------------------------------------------------------------------------
   fun {CreateDPI DpiType Flight CurrentTime}
      dpi(type: DpiType
          callsign: Flight.callsign
          gufi: Flight.gufi
          origin: Flight.origin
          destination: Flight.destination
          stand: Flight.assignedStand
          runway: Flight.assignedRunway
          sid: Flight.sidRoute
          tobt: Flight.tobt
          tsat: Flight.tsat
          ttot: Flight.ttot
          issuedAt: CurrentTime)
   end

   % --------------------------------------------------------------------------
   % FormatDPITelex: Formats structured DPI into standard telex string
   % --------------------------------------------------------------------------
   fun {FormatDPITelex DpiRec}
      TypeStr = case DpiRec.type
                of dpi_early then "E-DPI"
                [] dpi_target then "T-DPI"
                [] dpi_atc_pre then "A-DPI"
                [] dpi_sequenced then "SIR-DPI"
                [] dpi_cancel then "C-DPI"
                else "DPI"
                end
   in
      telex(header: TypeStr
            callsign: DpiRec.callsign
            orig: DpiRec.origin
            dest: DpiRec.destination
            runway: DpiRec.runway
            sid: DpiRec.sid
            tobt: DpiRec.tobt
            tsat: DpiRec.tsat
            ttot: DpiRec.ttot)
   end

end
