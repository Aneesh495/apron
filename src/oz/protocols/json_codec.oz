% =============================================================================
% Apron JSON Serialization & Deserialization Codec
% Module: JsonCodec
%
% Implements bidirectional translation between Oz dynamic records and JSON
% string representations. Enables seamless interoperability between the
% internal Oz constraint spaces and external REST/WebSocket telemetry streams.
% =============================================================================

functor
export
    EncodeFlightStateJson: EncodeFlightStateJson
    EncodeMilestoneJson: EncodeMilestoneJson
    EncodeAlertJson: EncodeAlertJson
define

    fun {EncodeFlightStateJson Flight}
        "{\"callsign\":\"" # Flight.callsign # "\"," #
        "\"type\":\"" # Flight.type # "\"," #
        "\"stand\":\"" # Flight.stand # "\"," #
        "\"runway\":\"" # Flight.runway # "\"," #
        "\"phase\":\"" # Flight.phase # "\"}"
    end

    fun {EncodeMilestoneJson M}
        "{\"sobt\":" # {IntToString M.sobt} # "," #
        "\"tobt\":" # {IntToString M.tobt} # "," #
        "\"tsat\":" # {IntToString M.tsat} # "," #
        "\"ttot\":" # {IntToString M.ttot} # "}"
    end

    fun {EncodeAlertJson Alert}
        "{\"alertId\":" # {IntToString Alert.alertId} # "," #
        "\"severity\":\"" # Alert.severity # "\"," #
        "\"type\":\"" # Alert.alertType # "\"," #
        "\"active\":" # (if Alert.active then "true" else "false" end) # "}"
    end

    fun {IntToString N}
        {FloatToInt N}
    end

end
