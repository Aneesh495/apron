% =============================================================================
% Apron Unit Test: Exhaustive RECAT-EU Wake Turbulence Pairwise Matrix
% Module: TestWakeTurbulenceComprehensive
% =============================================================================

functor
import
    WakeSeparation at '../../src/oz/sequencing/separation_matrix.oz'
    RecatClass at '../../src/oz/sequencing/recat_eu.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        Categories = ['super' 'heavy' 'medium' 'light']
        P F
    in
        {TestAllPairs Categories Categories 0 0 P F}
        Passed = P
        Failed = F
    end

    proc {TestAllPairs Leads Trails AccP AccF ?OutP ?OutF}
        case Leads
        of nil then
            OutP = AccP
            OutF = AccF
        [] L|LRest then
            SubP SubF
        in
            {TestOneLead L Trails 0 0 SubP SubF}
            {TestAllPairs LRest Trails AccP + SubP AccF + SubF OutP OutF}
        end
    end

    proc {TestOneLead Lead Trails AccP AccF ?OutP ?OutF}
        case Trails
        of nil then
            OutP = AccP
            OutF = AccF
        [] T|TRest then
            Dist = {WakeSeparation.GetDistanceSeparationNM Lead T}
            Time = {WakeSeparation.GetTimeSeparationSec Lead T}
        in
            if Dist >= 3.0 andthen Time >= 60 then
                {TestOneLead Lead TRest AccP + 1 AccF OutP OutF}
            else
                {TestOneLead Lead TRest AccP AccF + 1 OutP OutF}
            end
        end
    end

end
