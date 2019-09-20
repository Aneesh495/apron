% =============================================================================
% Apron IATA AIDX XML Flight Update Serializer
% Module: AIDXSerializer
%
% Implements outbound serialization of flight turnaround and milestone records
% into standard IATA AIDX (Airport-Airline Data Exchange) XML document strings.
% Emits compliant IATA_AIDX_FlightLegNotifRQ payloads for stakeholder exchange.
% =============================================================================

functor
export
    SerializeAIDXFlightLeg: SerializeAIDXFlightLeg
    FormatAIDXEnvelope: FormatAIDXEnvelope
define

    fun {SerializeAIDXFlightLeg FlightLeg}
        % Produces XML fragment for FlightLeg
        "<FlightLeg>\n" #
        "  <FlightIdentification>\n" #
        "    <Airline>" # FlightLeg.airline # "</Airline>\n" #
        "    <FlightNumber>" # FlightLeg.flightNumber # "</FlightNumber>\n" #
        "    <DepartureAirport>" # FlightLeg.origin # "</DepartureAirport>\n" #
        "    <ArrivalAirport>" # FlightLeg.destination # "</ArrivalAirport>\n" #
        "  </FlightIdentification>\n" #
        "  <AircraftInfo>\n" #
        "    <AircraftType>" # FlightLeg.acType # "</AircraftType>\n" #
        "    <AircraftRegistration>" # FlightLeg.registration # "</AircraftRegistration>\n" #
        "  </AircraftInfo>\n" #
        "  <AirportResources>\n" #
        "    <AircraftStand>" # FlightLeg.stand # "</AircraftStand>\n" #
        "  </AirportResources>\n" #
        "  <MilestoneTimes>\n" #
        "    <SOBT>" # {IntToString FlightLeg.sobt} # "</SOBT>\n" #
        "    <TOBT>" # {IntToString FlightLeg.tobt} # "</TOBT>\n" #
        "    <TSAT>" # {IntToString FlightLeg.tsat} # "</TSAT>\n" #
        "    <TTOT>" # {IntToString FlightLeg.ttot} # "</TTOT>\n" #
        "  </MilestoneTimes>\n" #
        "</FlightLeg>"
    end

    fun {FormatAIDXEnvelope ContentBody Timestamp}
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" #
        "<IATA_AIDX_FlightLegNotifRQ TimeStamp=\"" # {IntToString Timestamp} # "\">\n" #
        ContentBody # "\n" #
        "</IATA_AIDX_FlightLegNotifRQ>\n"
    end

    fun {IntToString N}
        {FloatToInt N} % fallback conversion or integer to string
    end

end
