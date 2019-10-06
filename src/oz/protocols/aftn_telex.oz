% =============================================================================
% Apron AFTN / AMHS Departure Notification Generator
% Module: AFTNTelex
%
% Implements formatting of standard ICAO telegraphic air traffic service
% messages for the Aeronautical Fixed Telecommunication Network (AFTN) and
% ATS Message Handling System (AMHS). Generates DEP, ARR, DLA, and CNL telexes.
% =============================================================================

functor
export
    FormatDEPMessage: FormatDEPMessage
    FormatARRMessage: FormatARRMessage
    FormatDLAMessage: FormatDLAMessage
    FormatCNLMessage: FormatCNLMessage
define

    % Generates standard ICAO DEP message:
    % (DEP-CALLSIGN-ADEP[TIME]-ADES-DOF/YYMMDD)
    fun {FormatDEPMessage Callsign Adep Atot Ades Dof}
        "(DEP-" # Callsign #
        "-" # Adep # {FormatTime Atot} #
        "-" # Ades #
        "-DOF/" # Dof # ")"
    end

    % Generates standard ICAO ARR message:
    % (ARR-CALLSIGN-ADEP-ADES[TIME])
    fun {FormatARRMessage Callsign Adep Ades Aldt}
        "(ARR-" # Callsign #
        "-" # Adep #
        "-" # Ades # {FormatTime Aldt} # ")"
    end

    % Generates standard ICAO DLA message:
    % (DLA-CALLSIGN-ADEP[NEW_EOBT]-ADES)
    fun {FormatDLAMessage Callsign Adep NewEobt Ades}
        "(DLA-" # Callsign #
        "-" # Adep # {FormatTime NewEobt} #
        "-" # Ades # ")"
    end

    % Generates standard ICAO CNL message:
    % (CNL-CALLSIGN-ADEP-ADES-DOF/YYMMDD)
    fun {FormatCNLMessage Callsign Adep Ades Dof}
        "(CNL-" # Callsign #
        "-" # Adep #
        "-" # Ades #
        "-DOF/" # Dof # ")"
    end

    fun {FormatTime Seconds}
        Hours = (Seconds div 3600) mod 24
        Mins = (Seconds mod 3600) div 60
        HStr = if Hours < 10 then "0" # {IntToString Hours} else {IntToString Hours} end
        MStr = if Mins < 10 then "0" # {IntToString Mins} else {IntToString Mins} end
    in
        HStr # MStr
    end

    fun {IntToString N}
        {FloatToInt N}
    end

end
