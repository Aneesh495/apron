% =============================================================================
% Apron Atmospheric Wind & Runway Weather Model
% Module: WindWeather
%
% Implements dynamic meteorological simulation, wind vector decomposition
% (headwind, crosswind, and tailwind components relative to runway headings),
% gust perturbations, and active runway operational direction selection.
% =============================================================================

functor
import
    Numeric at '../utils/numeric.oz'
export
    DecomposeWind: DecomposeWind
    SelectBestRunwayHeading: SelectBestRunwayHeading
    CalculateGustEffect: CalculateGustEffect
define

    % Decomposes wind velocity vector into headwind and crosswind components:
    % WindSpeed in knots, WindDir in degrees, RunwayHeading in degrees
    fun {DecomposeWind WindSpeed WindDir RunwayHeading}
        AngleDiffDeg = {AbsFloat (WindDir - RunwayHeading)}
        AngleRad = AngleDiffDeg * 3.141592653589793 / 180.0
        Headwind = WindSpeed * {Cos AngleRad}
        Crosswind = WindSpeed * {Sin AngleRad}
    in
        windComponents(headwind: Headwind
                       crosswind: Crosswind
                       tailwind: (if Headwind < 0.0 then ~Headwind else 0.0 end))
    end

    % Evaluates a list of candidate runway magnetic headings and selects the
    % one offering the maximum positive headwind component
    fun {SelectBestRunwayHeading Headings WindSpeed WindDir}
        {FindMaxHeadwind Headings WindSpeed WindDir none ~999.0}
    end

    fun {FindMaxHeadwind Headings WindSpeed WindDir BestHdg MaxHw}
        case Headings
        of nil then BestHdg
        [] H|Rest then
            Comp = {DecomposeWind WindSpeed WindDir H}
        in
            if Comp.headwind > MaxHw then
                {FindMaxHeadwind Rest WindSpeed WindDir H Comp.headwind}
            else
                {FindMaxHeadwind Rest WindSpeed WindDir BestHdg MaxHw}
            end
        end
    end

    fun {CalculateGustEffect BaseWind GustPeak RandomFactor}
        BaseWind + (GustPeak - BaseWind) * RandomFactor
    end

    fun {AbsFloat X}
        if X < 0.0 then ~X else X end
    end

end
