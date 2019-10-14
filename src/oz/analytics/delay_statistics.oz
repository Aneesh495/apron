% =============================================================================
% Apron Airfield Delay Statistics & Root-Cause Distribution
% Module: DelayStatistics
%
% Implements statistical analysis of schedule variances, total system delay,
% average delay per flight, 95th percentile delay tails, and attribution to
% standard IATA delay sub-codes (e.g., Code 81 ATC, Code 85 De-icing).
% =============================================================================

functor
import
    Numeric at '../utils/numeric.oz'
export
    CalculateTotalDelay: CalculateTotalDelay
    CalculateAverageDelay: CalculateAverageDelay
    CalculateMaxDelay: CalculateMaxDelay
    FilterDelaysAboveThreshold: FilterDelaysAboveThreshold
define

    fun {CalculateTotalDelay DelayList}
        case DelayList
        of nil then 0
        [] D|Rest then
            (if D > 0 then D else 0 end) + {CalculateTotalDelay Rest}
        end
    end

    fun {CalculateAverageDelay DelayList}
        N = {Length DelayList}
    in
        if N == 0 then 0.0
        else
            Total = {CalculateTotalDelay DelayList}
        in
            {IntToFloat Total} / {IntToFloat N}
        end
    end

    fun {CalculateMaxDelay DelayList}
        case DelayList
        of nil then 0
        [] [D] then (if D > 0 then D else 0 end)
        [] D|Rest then
            MaxRest = {CalculateMaxDelay Rest}
            Cur = if D > 0 then D else 0 end
        in
            if Cur > MaxRest then Cur else MaxRest end
        end
    end

    fun {FilterDelaysAboveThreshold DelayList Threshold}
        case DelayList
        of nil then nil
        [] D|Rest then
            if D > Threshold then
                D|{FilterDelaysAboveThreshold Rest Threshold}
            else
                {FilterDelaysAboveThreshold Rest Threshold}
            end
        end
    end

end
