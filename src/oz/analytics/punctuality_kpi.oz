% =============================================================================
% Apron Flight Punctuality & Slot Compliance Key Performance Indicators
% Module: PunctualityKPI
%
% Implements global airline and airport punctuality benchmarks:
% - D0: Departure punctuality (Actual Off-Block within 0 minutes of SOBT)
% - D15: Standard industry punctuality (AOBT within 15 minutes of SOBT)
% - A14: Arrival punctuality (Actual In-Block within 14 minutes of SIBT)
% - TSAT Window Compliance: Startup clearance within [-5, +5] minutes of TSAT
% - ATFM Slot Compliance: Take-off within [-5, +10] minutes of CTOT
% =============================================================================

functor
export
    CalculateD0Percentage: CalculateD0Percentage
    CalculateD15Percentage: CalculateD15Percentage
    CalculateTSATCompliance: CalculateTSATCompliance
    CalculateATFMCompliance: CalculateATFMCompliance
define

    fun {CalculateD0Percentage DelayList}
        Total = {Length DelayList}
        OnTime = {CountMatches DelayList fun {$ D} D =< 0 end}
    in
        if Total == 0 then 100.0
        else
            ({IntToFloat OnTime} / {IntToFloat Total}) * 100.0
        end
    end

    fun {CalculateD15Percentage DelayList}
        Total = {Length DelayList}
        % 15 minutes = 900 seconds
        Within15 = {CountMatches DelayList fun {$ D} D =< 900 end}
    in
        if Total == 0 then 100.0
        else
            ({IntToFloat Within15} / {IntToFloat Total}) * 100.0
        end
    end

    % TSAT tolerance: -5 min (-300s) to +5 min (+300s)
    fun {CalculateTSATCompliance ActualStartups TSATs}
        Diffs = {ComputeDifferences ActualStartups TSATs}
        Total = {Length Diffs}
        Compliant = {CountMatches Diffs fun {$ D} D >= ~300 andthen D =< 300 end}
    in
        if Total == 0 then 100.0
        else
            ({IntToFloat Compliant} / {IntToFloat Total}) * 100.0
        end
    end

    % ATFM CTOT tolerance: -5 min (-300s) to +10 min (+600s)
    fun {CalculateATFMCompliance ActualTakeoffs CTOTs}
        Diffs = {ComputeDifferences ActualTakeoffs CTOTs}
        Total = {Length Diffs}
        Compliant = {CountMatches Diffs fun {$ D} D >= ~300 andthen D =< 600 end}
    in
        if Total == 0 then 100.0
        else
            ({IntToFloat Compliant} / {IntToFloat Total}) * 100.0
        end
    end

    fun {CountMatches List Pred}
        case List
        of nil then 0
        [] H|T then
            (if {Pred H} then 1 else 0 end) + {CountMatches T Pred}
        end
    end

    fun {ComputeDifferences L1 L2}
        case L1#L2
        of (X|Xs)#(Y|Ys) then (X - Y)|{ComputeDifferences Xs Ys}
        else nil
        end
    end

end
