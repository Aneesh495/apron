% =============================================================================
% Apron Unit Test: Runway Sequencing and Wake Turbulence
% Module: TestRunwaySequencing
% =============================================================================

functor
import
    WakeSeparation at '../../src/oz/sequencing/separation_matrix.oz'
    SidDivergence at '../../src/oz/sequencing/sid_divergence.oz'
    MixedMode at '../../src/oz/sequencing/mixed_mode.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        P1 F1 P2 F2 P3 F3
    in
        {TestWakeMatrix P1 F1}
        {TestSidDivergence P2 F2}
        {TestMixedMode P3 F3}
        Passed = P1 + P2 + P3
        Failed = F1 + F2 + F3
    end

    proc {TestWakeMatrix ?P ?F}
        SepDist = {WakeSeparation.GetDistanceSeparationNM 'heavy' 'medium'}
        SepTime = {WakeSeparation.GetTimeSeparationSec 'heavy' 'medium'}
    in
        if SepDist >= 4.0 andthen SepTime >= 90 then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestSidDivergence ?P ?F}
        SpacingSame = {SidDivergence.GetDepartureSpacingSec 'BPK1' 'BPK1'}
        SpacingDivergent = {SidDivergence.GetDepartureSpacingSec 'BPK1' 'MID2'}
    in
        if SpacingSame > SpacingDivergent then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestMixedMode ?P ?F}
        CanInsert = {MixedMode.CanInsertDeparture 1000 1200 60}
    in
        if CanInsert then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

end
