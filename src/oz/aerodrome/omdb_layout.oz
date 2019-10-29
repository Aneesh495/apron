% =============================================================================
% Apron Aerodrome Layout: Dubai International Airport (OMDB)
% Module: OMDBAirfieldLayout
%
% Implements the topological network model, dual parallel runways (12L/30R,
% 12R/30L), parallel rapid exit taxiways, and Emirates mega-hub A380/B77W
% contact stands at Concourse A, B, C, and D.
% =============================================================================

functor
import
    AerodromeNet at 'network.oz'
    RunwayThresholds at 'runways.oz'
    StandAllocation at 'stands.oz'
export
    GetOMDBLayout: GetOMDBLayout
    GetOMDBRunways: GetOMDBRunways
    GetOMDBStands: GetOMDBStands
define

    fun {GetOMDBRunways}
        [
            rwy(designator: "12L" heading: 121.0 length: 4450 width: 60
                mode: mixed tora: 4450 toda: 4450 asda: 4450 lda: 4000
                dispThresh: 450 stopway: 0 clearway: 0)
            rwy(designator: "30R" heading: 301.0 length: 4450 width: 60
                mode: mixed tora: 4450 toda: 4450 asda: 4450 lda: 4450
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "12R" heading: 121.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 4000
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "30L" heading: 301.0 length: 4000 width: 60
                mode: mixed tora: 4000 toda: 4000 asda: 4000 lda: 3600
                dispThresh: 400 stopway: 0 clearway: 0)
        ]
    end

    fun {GetOMDBStands}
        [
            stand(id: "A01" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "A02" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "A03" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "B01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "B02" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "C01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "D01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "R10" category: 'super' maxWingspan: 80.0 contact: false currentFlight: none)
        ]
    end

    fun {GetOMDBLayout}
        airport(icao: "OMDB"
                iata: "DXB"
                name: "Dubai International Airport"
                arp: coord(lat: 25.2528 lon: 55.3644 elev: 19.0)
                runways: {GetOMDBRunways}
                stands: {GetOMDBStands})
    end

end
