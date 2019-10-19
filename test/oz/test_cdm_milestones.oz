% =============================================================================
% Apron Unit Test: A-CDM Milestones and Turnaround Logic
% Module: TestCDMMilestones
% =============================================================================

functor
import
    Milestones at '../../src/oz/cdm/milestones.oz'
    TobtValidation at '../../src/oz/cdm/tobt.oz'
    TsatSequencing at '../../src/oz/cdm/tsat.oz'
    DeicingCalc at '../../src/oz/cdm/deicing.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        P1 F1 P2 F2 P3 F3 P4 F4
    in
        {TestMilestoneSequence P1 F1}
        {TestTobtValidation P2 F2}
        {TestTsatComputation P3 F3}
        {TestDeicingHoldover P4 F4}
        Passed = P1 + P2 + P3 + P4
        Failed = F1 + F2 + F3 + F4
    end

    proc {TestMilestoneSequence ?P ?F}
        M0 = {Milestones.CreateTurnaroundState "BAW142" 1000}
        M1 = {Milestones.AdvanceMilestone M0 'eldt' 1100}
        M2 = {Milestones.AdvanceMilestone M1 'aldt' 1120}
    in
        if M2.aldt == 1120 andthen M2.currentMilestone == 'aldt' then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestTobtValidation ?P ?F}
        Valid = {TobtValidation.ValidateTOBT 1200 1205 180}
        Invalid = {TobtValidation.ValidateTOBT 1200 900 180}
    in
        if Valid == ok andthen Invalid == error(tobt_in_past) then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestTsatComputation ?P ?F}
        Tsat = {TsatSequencing.ComputeTSAT 1200 1230 600}
    in
        if Tsat >= 1200 then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestDeicingHoldover ?P ?F}
        Hot = {DeicingCalc.CalculateHoldoverTime 'type_iv' 'light_snow' ~2.0}
    in
        if Hot.minMinutes > 0 andthen Hot.maxMinutes >= Hot.minMinutes then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

end
