% =============================================================================
% Apron Aircraft Fuel Burn & Emissions Calculator (ICAO Doc 9883)
% Module: FuelEmissions
%
% Implements engine idle fuel burn models, Auxiliary Power Unit (APU) fuel
% consumption, and greenhouse gas emission metrics (CO2 and NOx) in compliance
% with ICAO Doc 9883 and the ICAO Aircraft Engine Emissions Databank.
% Quantifies fuel savings achieved by A-CDM virtual queue engine-off holds.
% =============================================================================

functor
export
    GetIdleFuelFlowKgPerSec: GetIdleFuelFlowKgPerSec
    CalculateTaxiFuelBurn: CalculateTaxiFuelBurn
    CalculateCO2Emissions: CalculateCO2Emissions
    CalculateNOxEmissions: CalculateNOxEmissions
    ComputeGateHoldSavings: ComputeGateHoldSavings
define

    % Fuel burn constants:
    % 3.16 kg of CO2 emitted per 1.0 kg of Jet-A1 kerosene burned
    % NOx emissions index ~ 4.5 g NOx per kg of fuel at idle throttle settings

    fun {GetIdleFuelFlowKgPerSec AcType SingleEngineTaxi}
        BaseFlow = case AcType
                   of 'A388' then 1.12
                   [] 'B77W' then 0.56
                   [] 'B789' then 0.38
                   [] 'A359' then 0.40
                   [] 'A320' then 0.15
                   [] 'A321' then 0.16
                   [] 'B738' then 0.16
                   [] 'E190' then 0.09
                   else 0.20
                   end
    in
        if SingleEngineTaxi then
            BaseFlow * 0.65 % 35% savings from single-engine taxi operations
        else
            BaseFlow
        end
    end

    fun {CalculateTaxiFuelBurn AcType TaxiTimeSec SingleEngineTaxi}
        Flow = {GetIdleFuelFlowKgPerSec AcType SingleEngineTaxi}
    in
        Flow * {IntToFloat TaxiTimeSec}
    end

    fun {CalculateCO2Emissions FuelKg}
        FuelKg * 3.16
    end

    fun {CalculateNOxEmissions FuelKg}
        FuelKg * 4.5 % returns grams of NOx
    end

    % Computes fuel and emissions saved by holding aircraft at gate with engines
    % off during TSAT delay instead of idling in taxiway queues
    fun {ComputeGateHoldSavings AcType HoldTimeSec}
        IdlingFuel = {CalculateTaxiFuelBurn AcType HoldTimeSec false}
        % APU burn rate ~ 0.035 kg/s (approx 125 kg/hour)
        ApuFuel = 0.035 * {IntToFloat HoldTimeSec}
        NetFuelSaved = IdlingFuel - ApuFuel
        NetCO2Saved = {CalculateCO2Emissions NetFuelSaved}
    in
        savings(fuelKg: NetFuelSaved
                co2Kg: NetCO2Saved
                idlingFuelKg: IdlingFuel
                apuFuelKg: ApuFuel)
    end

end
