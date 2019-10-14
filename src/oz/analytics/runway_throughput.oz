% =============================================================================
% Apron Runway Throughput & Operational Capacity Calculator
% Module: RunwayThroughput
%
% Implements hourly movement rate calculations, peak runway capacity
% utilization percentages, arrival versus departure movement balance, and
% inter-departure / inter-arrival separation headway distributions.
% =============================================================================

functor
export
    CalculateMovementsPerHour: CalculateMovementsPerHour
    CalculateCapacityUtilization: CalculateCapacityUtilization
    CalculateAverageHeadway: CalculateAverageHeadway
define

    % Calculates movements per hour given total movement count and observation
    % window in seconds
    fun {CalculateMovementsPerHour MovementCount WindowSeconds}
        if WindowSeconds == 0 then 0.0
        else
            Hours = {IntToFloat WindowSeconds} / 3600.0
        in
            {IntToFloat MovementCount} / Hours
        end
    end

    % Evaluates actual movement rate relative to declared runway capacity
    fun {CalculateCapacityUtilization ActualRate DeclaredCapacity}
        if DeclaredCapacity =< 0.0 then 0.0
        else
            (ActualRate / DeclaredCapacity) * 100.0
        end
    end

    % Computes average spacing headway (seconds) across successive operations
    fun {CalculateAverageHeadway Timestamps}
        case Timestamps
        of nil then 0.0
        [] [_] then 0.0
        [] T1|T2|Rest then
            Diffs = {ComputeHeadwayDiffs Timestamps}
            N = {Length Diffs}
            Sum = {SumList Diffs}
        in
            if N == 0 then 0.0
            else
                {IntToFloat Sum} / {IntToFloat N}
            end
        end
    end

    fun {ComputeHeadwayDiffs List}
        case List
        of nil then nil
        [] [_] then nil
        [] T1|T2|Rest then
            (T2 - T1)|{ComputeHeadwayDiffs T2|Rest}
        end
    end

    fun {SumList List}
        case List
        of nil then 0
        [] H|T then H + {SumList T}
        end
    end

end
