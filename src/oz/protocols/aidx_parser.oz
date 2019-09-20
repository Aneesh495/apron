% =============================================================================
% Apron IATA AIDX XML Flight Update Parser
% Module: AIDXParser
%
% Implements decoding and record extraction for IATA Airport-Airline Data
% Exchange (AIDX) XML documents. Extracts flight identifiers, equipment types,
% scheduled times, estimated milestones (SOBT, TOBT, TSAT, TTOT), and stand
% assignments from IATA_AIDX_FlightLegNotifRQ schemas.
% =============================================================================

functor
export
    ParseAIDXFlightLeg: ParseAIDXFlightLeg
    ExtractMilestones: ExtractMilestones
    ExtractFlightKey: ExtractFlightKey
define

    % Represents a parsed AIDX Flight Leg:
    % flightLeg(airline: Airline
    %           flightNumber: Number
    %           origin: Origin
    %           destination: Destination
    %           acType: Type
    %           registration: Reg
    %           stand: Stand
    %           sobt: SOBT
    %           tobt: TOBT
    %           tsat: TSAT
    %           ttot: TTOT)

    fun {ParseAIDXFlightLeg XmlRecord}
        % XmlRecord is an associative record or parsed AST of AIDX XML elements
        Airline = {CondSelect XmlRecord airline "UNKNOWN"}
        FlightNum = {CondSelect XmlRecord flightNumber "0000"}
        Origin = {CondSelect XmlRecord origin "ZZZZ"}
        Dest = {CondSelect XmlRecord destination "ZZZZ"}
        AcType = {CondSelect XmlRecord aircraftType "A320"}
        Reg = {CondSelect XmlRecord registration "NONE"}
        Stand = {CondSelect XmlRecord stand "UNASSIGNED"}
        Sobt = {CondSelect XmlRecord sobt 0}
        Tobt = {CondSelect XmlRecord tobt Sobt}
        Tsat = {CondSelect XmlRecord tsat 0}
        Ttot = {CondSelect XmlRecord ttot 0}
    in
        flightLeg(airline: Airline
                  flightNumber: FlightNum
                  origin: Origin
                  destination: Dest
                  acType: AcType
                  registration: Reg
                  stand: Stand
                  sobt: Sobt
                  tobt: Tobt
                  tsat: Tsat
                  ttot: Ttot)
    end

    fun {ExtractMilestones FlightLeg}
        milestones(sobt: FlightLeg.sobt
                   tobt: FlightLeg.tobt
                   tsat: FlightLeg.tsat
                   ttot: FlightLeg.ttot)
    end

    fun {ExtractFlightKey FlightLeg}
        % Combines airline and flight number: e.g. BAW142
        FlightLeg.airline # FlightLeg.flightNumber
    end

end
