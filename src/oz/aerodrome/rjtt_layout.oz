% =============================================================================
% Apron Aerodrome Layout: Tokyo Haneda Airport (RJTT)
% Module: RJTTAirfieldLayout
%
% Implements the topological network model, four intersecting and offset
% runways (16R/34L Runway A, 16L/34R Runway C, 04/22 Runway B, 05/23 Runway D
% offshore pier), and Terminal 1, 2, and 3 gate clusters.
% =============================================================================

functor
import
    AerodromeNet at 'network.oz'
    RunwayThresholds at 'runways.oz'
    StandAllocation at 'stands.oz'
export
    GetRJTTLayout: GetRJTTLayout
    GetRJTTRunways: GetRJTTRunways
    GetRJTTStands: GetRJTTStands
define

    fun {GetRJTTRunways}
        [
            rwy(designator: "16R" heading: 157.0 length: 3000 width: 60
                mode: departure tora: 3000 toda: 3000 asda: 3000 lda: 3000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "34L" heading: 337.0 length: 3000 width: 60
                mode: arrival tora: 3000 toda: 3000 asda: 3000 lda: 3000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "16L" heading: 157.0 length: 3360 width: 60
                mode: departure tora: 3360 toda: 3360 asda: 3360 lda: 3360
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "34R" heading: 337.0 length: 3360 width: 60
                mode: arrival tora: 3360 toda: 3360 asda: 3360 lda: 3360
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "04" heading: 43.0 length: 2500 width: 60
                mode: arrival tora: 2500 toda: 2500 asda: 2500 lda: 2500
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "22" heading: 223.0 length: 2500 width: 60
                mode: departure tora: 2500 toda: 2500 asda: 2500 lda: 2500
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "05" heading: 47.0 length: 2500 width: 60
                mode: departure tora: 2500 toda: 2500 asda: 2500 lda: 2500
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "23" heading: 227.0 length: 2500 width: 60
                mode: arrival tora: 2500 toda: 2500 asda: 2500 lda: 2500
                dispThresh: 0 stopway: 0 clearway: 0)
        ]
    end

    fun {GetRJTTStands}
        [
            stand(id: "T1_05" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T1_08" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T2_60" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T2_65" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T3_110" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T3_112" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
        ]
    end

    fun {GetRJTTLayout}
        airport(icao: "RJTT"
                iata: "HND"
                name: "Tokyo Haneda Airport"
                arp: coord(lat: 35.5494 lon: 139.7798 elev: 6.4)
                runways: {GetRJTTRunways}
                stands: {GetRJTTStands})
    end

end
