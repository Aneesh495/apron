% =============================================================================
% Apron Unit Test: Airfield Topologies & Airport Layout Models
% Module: TestAirfieldTopologies
% =============================================================================

functor
import
    Heathrow at '../../src/oz/aerodrome/egll_layout.oz'
    Frankfurt at '../../src/oz/aerodrome/eddf_layout.oz'
    Schiphol at '../../src/oz/aerodrome/eham_layout.oz'
    JFK at '../../src/oz/aerodrome/kjfk_layout.oz'
    Dubai at '../../src/oz/aerodrome/omdb_layout.oz'
    ParisCDG at '../../src/oz/aerodrome/lfpg_layout.oz'
    Haneda at '../../src/oz/aerodrome/rjtt_layout.oz'
    Changi at '../../src/oz/aerodrome/wsss_layout.oz'
export
    RunTests: RunTests
define

    proc {RunTests ?Passed ?Failed}
        P1 F1 P2 F2 P3 F3 P4 F4 P5 F5 P6 F6 P7 F7 P8 F8
    in
        {TestAirport Heathrow.GetEGLLLayout "EGLL" 4 P1 F1}
        {TestAirport Frankfurt.GetEDDFLayout "EDDF" 7 P2 F2}
        {TestAirport Schiphol.GetEHAMLayout "EHAM" 12 P3 F3}
        {TestAirport JFK.GetJFKLayout "KJFK" 8 P4 F4}
        {TestAirport Dubai.GetOMDBLayout "OMDB" 4 P5 F5}
        {TestAirport ParisCDG.GetLFPGLayout "LFPG" 8 P6 F6}
        {TestAirport Haneda.GetRJTTLayout "RJTT" 8 P7 F7}
        {TestAirport Changi.GetWSSSLayout "WSSS" 6 P8 F8}
        Passed = P1 + P2 + P3 + P4 + P5 + P6 + P7 + P8
        Failed = F1 + F2 + F3 + F4 + F5 + F6 + F7 + F8
    end

    proc {TestAirport Layout ExpectedIcao ExpectedMinRunways ?P ?F}
        ActualIcao = Layout.icao
        RwyCount = {Length Layout.runways}
        StandCount = {Length Layout.stands}
    in
        if ActualIcao == ExpectedIcao andthen RwyCount >= ExpectedMinRunways andthen StandCount > 0 then
            P = 1 F = 0
        else
            P = 0 F = 1
        end
    end

end
