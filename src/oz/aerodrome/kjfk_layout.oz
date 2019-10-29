% =============================================================================
% Apron Aerodrome Layout: John F. Kennedy International Airport (KJFK)
% Module: JFKAirfieldLayout
%
% Implements the topological network model, runway configurations, taxiway
% networks, and terminal gate allocations for New York JFK (KJFK).
% Runways: 04L/22R, 04R/22L, 13L/31R, 13R/31L.
% =============================================================================

functor
import
    AerodromeNet at 'network.oz'
    RunwayThresholds at 'runways.oz'
    TaxiwayKinematics at 'taxiways.oz'
    StandAllocation at 'stands.oz'
export
    GetJFKLayout: GetJFKLayout
    GetJFKRunways: GetJFKRunways
    GetJFKStands: GetJFKStands
define

    fun {GetJFKRunways}
        [
            rwy(designator: "04L" heading: 44.0 length: 3460 width: 45
                mode: arrival tora: 3460 toda: 3460 asda: 3460 lda: 3182
                dispThresh: 278 stopway: 0 clearway: 0)
            rwy(designator: "22R" heading: 224.0 length: 3460 width: 45
                mode: departure tora: 3460 toda: 3460 asda: 3460 lda: 3460
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "04R" heading: 44.0 length: 2560 width: 60
                mode: mixed tora: 2560 toda: 2560 asda: 2560 lda: 2560
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "22L" heading: 224.0 length: 2560 width: 60
                mode: arrival tora: 2560 toda: 2560 asda: 2560 lda: 2560
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "13L" heading: 134.0 length: 4423 width: 45
                mode: departure tora: 4423 toda: 4423 asda: 4423 lda: 4423
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "31R" heading: 314.0 length: 4423 width: 45
                mode: arrival tora: 4423 toda: 4423 asda: 4423 lda: 4060
                dispThresh: 363 stopway: 0 clearway: 0)
            rwy(designator: "13R" heading: 134.0 length: 3048 width: 45
                mode: mixed tora: 3048 toda: 3048 asda: 3048 lda: 3048
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "31L" heading: 314.0 length: 3048 width: 45
                mode: departure tora: 3048 toda: 3048 asda: 3048 lda: 3048
                dispThresh: 0 stopway: 0 clearway: 0)
        ]
    end

    fun {GetJFKStands}
        [
            stand(id: "T1_01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T1_02" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T1_03" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T4_A02" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T4_A03" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T4_B20" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T4_B22" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T5_01" category: 'medium' maxWingspan: 36.0 contact: true currentFlight: none)
            stand(id: "T5_02" category: 'medium' maxWingspan: 36.0 contact: true currentFlight: none)
            stand(id: "T7_01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T8_01" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T8_02" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
        ]
    end

    fun {GetJFKLayout}
        airport(icao: "KJFK"
                iata: "JFK"
                name: "John F. Kennedy International Airport"
                arp: coord(lat: 40.6397 lon: ~73.7789 elev: 4.0)
                runways: {GetJFKRunways}
                stands: {GetJFKStands})
    end

end
