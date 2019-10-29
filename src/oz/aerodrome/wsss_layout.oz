% =============================================================================
% Apron Aerodrome Layout: Singapore Changi Airport (WSSS)
% Module: WSSSAirfieldLayout
%
% Implements the topological network model, three parallel runways (02L/20R,
% 02C/20C, 02R/20R), Jewel Changi central inter-terminal bridges, and
% Terminal 1, 2, 3, and 4 contact and remote gate allocation matrices.
% =============================================================================

functor
import
    AerodromeNet at 'network.oz'
    RunwayThresholds at 'runways.oz'
    StandAllocation at 'stands.oz'
export
    GetWSSSLayout: GetWSSSLayout
    GetWSSSRunways: GetWSSSRunways
    GetWSSSStands: GetWSSSStands
define

    fun {GetWSSSRunways}
        [
            rwy(designator: "02L" heading: 23.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 4000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "20R" heading: 203.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 4000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "02C" heading: 23.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 4000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "20C" heading: 203.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 4000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "02R" heading: 23.0 length: 2750 width: 60
                mode: mixed tora: 2750 toda: 2750 asda: 2750 lda: 2750
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "20L" heading: 203.0 length: 2750 width: 60
                mode: mixed tora: 2750 toda: 2750 asda: 2750 lda: 2750
                dispThresh: 0 stopway: 0 clearway: 0)
        ]
    end

    fun {GetWSSSStands}
        [
            stand(id: "T1_C11" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T2_E02" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T3_B01" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T3_B02" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T3_B03" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T4_G01" category: 'medium' maxWingspan: 36.0 contact: true currentFlight: none)
        ]
    end

    fun {GetWSSSLayout}
        airport(icao: "WSSS"
                iata: "SIN"
                name: "Singapore Changi Airport"
                arp: coord(lat: 1.3644 lon: 103.9915 elev: 7.0)
                runways: {GetWSSSRunways}
                stands: {GetWSSSStands})
    end

end
