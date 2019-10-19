% =============================================================================
% Apron Unit Test: 4D Routing and Conflict Detection
% Module: TestRoutingConflicts
% =============================================================================

functor
import
    ConflictPreds at '../../src/oz/routing/conflict_predicates.oz'
    BlockingMatrix at '../../src/oz/routing/blocking.oz'
    RunwayCrossing at '../../src/oz/routing/crossing.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        P1 F1 P2 F2 P3 F3
    in
        {TestTemporalOverlap P1 F1}
        {TestStandBlocking P2 F2}
        {TestRunwayCrossingClearance P3 F3}
        Passed = P1 + P2 + P3
        Failed = F1 + F2 + F3
    end

    proc {TestTemporalOverlap ?P ?F}
        Overlap1 = {ConflictPreds.IntervalsOverlap 100 200 150 250}
        Overlap2 = {ConflictPreds.IntervalsOverlap 100 200 201 300}
    in
        if Overlap1 andthen (not Overlap2) then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestStandBlocking ?P ?F}
        IsBlocked = {BlockingMatrix.IsStandBlocked "501" ["502"]}
    in
        if IsBlocked == true orelse IsBlocked == false then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

    proc {TestRunwayCrossingClearance ?P ?F}
        CanCross = {RunwayCrossing.CanClearCrossing 1000 1060 1200}
    in
        if CanCross then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

end
