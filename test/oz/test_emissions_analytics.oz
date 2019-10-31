% =============================================================================
% Apron Unit Test: Environmental Emissions and Fuel Conservation
% Module: TestEmissionsAnalytics
% =============================================================================

functor
import
    FuelCalc at '../../src/oz/analytics/fuel_emissions.oz'
    DelayStats at '../../src/oz/analytics/delay_statistics.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        P1 F1 P2 F2 P3 F3
    in
        {TestFuelFlowRates P1 F1}
        {TestGateHoldSavings P2 F2}
        {TestDelayCalculations P3 F3}
        Passed = P1 + P2 + P3
        Failed = F1 + F2 + F3
    end

    proc {TestFuelFlowRates ?P ?F}
        FlowSuper = {FuelCalc.GetIdleFuelFlowKgPerSec 'A388' false}
        FlowHeavy = {FuelCalc.GetIdleFuelFlowKgPerSec 'B77W' false}
        FlowMedium = {FuelCalc.GetIdleFuelFlowKgPerSec 'A320' false}
    in
        if FlowSuper > FlowHeavy andthen FlowHeavy > FlowMedium then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestGateHoldSavings ?P ?F}
        Savings = {FuelCalc.ComputeGateHoldSavings 'B77W' 1200}
    in
        if Savings.fuelKg > 0.0 andthen Savings.co2Kg > 0.0 then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestDelayCalculations ?P ?F}
        Delays = [120 300 0 60 900]
        Total = {DelayStats.CalculateTotalDelay Delays}
        Avg = {DelayStats.CalculateAverageDelay Delays}
        Max = {DelayStats.CalculateMaxDelay Delays}
    in
        if Total == 1380 andthen Avg == 276.0 andthen Max == 900 then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

end
