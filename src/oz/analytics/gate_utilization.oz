% =============================================================================
% Apron Aircraft Stand & Gate Utilization Metrics
% Module: GateUtilization
%
% Calculates gate occupancy factors, contact vs remote stand allocation
% percentages, buffer time between consecutive aircraft rotations, and
% ground support equipment (tow tug) active duty cycle metrics.
% =============================================================================

functor
export
    CalculateStandOccupancyRate: CalculateStandOccupancyRate
    CalculateContactRatio: CalculateContactRatio
    CalculateAverageTurnaroundBuffer: CalculateAverageTurnaroundBuffer
define

    % Computes percentage of total available stand-hours occupied by aircraft
    fun {CalculateStandOccupancyRate TotalOccupiedSeconds StandCount HorizonSeconds}
        TotalAvailableSec = StandCount * HorizonSeconds
    in
        if TotalAvailableSec == 0 then 0.0
        else
            ({IntToFloat TotalOccupiedSeconds} / {IntToFloat TotalAvailableSec}) * 100.0
        end
    end

    % Computes ratio of contact stand operations vs remote stand operations
    fun {CalculateContactRatio ContactOps TotalOps}
        if TotalOps == 0 then 100.0
        else
            ({IntToFloat ContactOps} / {IntToFloat TotalOps}) * 100.0
        end
    end

    % Computes average safety buffer between consecutive flight departures and arrivals
    fun {CalculateAverageTurnaroundBuffer BufferList}
        N = {Length BufferList}
    in
        if N == 0 then 0.0
        else
            Sum = {SumList BufferList}
        in
            {IntToFloat Sum} / {IntToFloat N}
        end
    end

    fun {SumList List}
        case List
        of nil then 0
        [] H|T then H + {SumList T}
        end
    end

end
