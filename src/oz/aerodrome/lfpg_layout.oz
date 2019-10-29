% =============================================================================
% Apron Aerodrome Layout: Paris Charles de Gaulle (LFPG)
% Module: LFPGAirfieldLayout
%
% Implements the topological network model, four parallel runways configured
% in two independent pairs (09L/27R and 09R/27L north doublet, 08L/26R and
% 08R/26L south doublet), and Terminal 1, 2A-2G, and 3 gate complexes.
% =============================================================================

functor
import
    AerodromeNet at 'network.oz'
    RunwayThresholds at 'runways.oz'
    StandAllocation at 'stands.oz'
export
    GetLFPGLayout: GetLFPGLayout
    GetLFPGRunways: GetLFPGRunways
    GetLFPGStands: GetLFPGStands
define

    fun {GetLFPGRunways}
        [
            % North Doublet
            rwy(designator: "09L" heading: 86.0 length: 4215 width: 45
                mode: departure tora: 4215 toda: 4215 asda: 4215 lda: 4215
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "27R" heading: 266.0 length: 4215 width: 45
                mode: arrival tora: 4215 toda: 4215 asda: 4215 lda: 3900
                dispThresh: 315 stopway: 0 clearway: 0)
            rwy(designator: "09R" heading: 86.0 length: 2700 width: 60
                mode: arrival tora: 2700 toda: 2700 asda: 2700 lda: 2700
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "27L" heading: 266.0 length: 2700 width: 60
                mode: departure tora: 2700 toda: 2700 asda: 2700 lda: 2700
                dispThresh: 0 stopway: 0 clearway: 0)

            % South Doublet
            rwy(designator: "08L" heading: 86.0 length: 4200 width: 45
                mode: departure tora: 4200 toda: 4200 asda: 4200 lda: 4200
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "26R" heading: 266.0 length: 4200 width: 45
                mode: arrival tora: 4200 toda: 4200 asda: 4200 lda: 3850
                dispThresh: 350 stopway: 0 clearway: 0)
            rwy(designator: "08R" heading: 86.0 length: 2700 width: 60
                mode: arrival tora: 2700 toda: 2700 asda: 2700 lda: 2700
                dispThresh: 0 stopway: 0 clearway: 0)
            rwy(designator: "26L" heading: 266.0 length: 2700 width: 60
                mode: departure tora: 2700 toda: 2700 asda: 2700 lda: 2700
                dispThresh: 0 stopway: 0 clearway: 0)
        ]
    end

    fun {GetLFPGStands}
        [
            stand(id: "T1_10" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T2E_K30" category: 'super' maxWingspan: 80.0 contact: true currentFlight: none)
            stand(id: "T2E_K32" category: 'heavy' maxWingspan: 65.0 contact: true currentFlight: none)
            stand(id: "T2F_F11" category: 'medium' maxWingspan: 36.0 contact: true currentFlight: none)
            stand(id: "T2G_G01" category: 'light' maxWingspan: 29.0 contact: false currentFlight: none)
        ]
    end

    fun {GetLFPGLayout}
        airport(icao: "LFPG"
                iata: "CDG"
                name: "Paris Charles de Gaulle Airport"
                arp: coord(lat: 49.0097 lon: 2.5479 elev: 119.0)
                runways: {GetLFPGRunways}
                stands: {GetLFPGStands})
    end

end
