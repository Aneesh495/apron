% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.LayoutFRA
% Description: Detailed reference aerodrome topology for Frankfurt Main (EDDF).
%              Four-runway complex (07R/25L, 07C/25C, 07L/25R, Runway 18 West),
%              Terminal 1/2 piers and taxiway bridges.
% =============================================================================

functor
import
   Graph at 'graph.oz'
   Types at 'types.oz'
export
   BuildEDDF: BuildEDDF
define

   fun {BuildEDDF}
      G0 = {Graph.New}

      % Runway 25C / 07C (Center Runway)
      N_07C = node(id: "NODE_07C" name: "Threshold 07C" kind: Types.NODE_RUNWAY_THRESHOLD x: ~2000.0 y: 0.0 z: 100.0 code: Types.CODE_F)
      N_25C = node(id: "NODE_25C" name: "Threshold 25C" kind: Types.NODE_RUNWAY_THRESHOLD x: 2000.0 y: 0.0 z: 100.0 code: Types.CODE_F)

      % Runway 25L / 07R (South Runway)
      N_07R = node(id: "NODE_07R" name: "Threshold 07R" kind: Types.NODE_RUNWAY_THRESHOLD x: ~2000.0 y: ~518.0 z: 102.0 code: Types.CODE_F)
      N_25L = node(id: "NODE_25L" name: "Threshold 25L" kind: Types.NODE_RUNWAY_THRESHOLD x: 2000.0 y: ~518.0 z: 102.0 code: Types.CODE_F)

      % Runway 18 West (Dedicated Departure Runway)
      N_18  = node(id: "NODE_18" name: "Threshold 18" kind: Types.NODE_RUNWAY_THRESHOLD x: ~2100.0 y: 500.0 z: 105.0 code: Types.CODE_F)
      N_18_END = node(id: "NODE_18_END" name: "Runway 18 End" kind: Types.NODE_INTERSECTION x: ~2100.0 y: ~3500.0 z: 110.0 code: Types.CODE_F)

      % Runway 07L / 25R (Northwest Landing Runway)
      N_07L = node(id: "NODE_07L" name: "Threshold 07L" kind: Types.NODE_RUNWAY_THRESHOLD x: ~3200.0 y: 1800.0 z: 98.0 code: Types.CODE_E)
      N_25R = node(id: "NODE_25R" name: "Threshold 25R" kind: Types.NODE_RUNWAY_THRESHOLD x: ~400.0 y: 1800.0 z: 98.0 code: Types.CODE_E)

      % Terminal 1 Pier A/Z Stands (Lufthansa Mega-Hub)
      N_A15 = node(id: "STAND_A15" name: "Stand A15" kind: Types.NODE_STAND x: 200.0 y: 400.0 z: 100.0 code: Types.CODE_C)
      N_A20 = node(id: "STAND_A20" name: "Stand A20" kind: Types.NODE_STAND x: 300.0 y: 400.0 z: 100.0 code: Types.CODE_C)
      N_Z15 = node(id: "STAND_Z15" name: "Stand Z15 (A380 Capable)" kind: Types.NODE_STAND x: 250.0 y: 480.0 z: 100.0 code: Types.CODE_F)
      N_Z25 = node(id: "STAND_Z25" name: "Stand Z25 (B747-8)" kind: Types.NODE_STAND x: 350.0 y: 480.0 z: 100.0 code: Types.CODE_F)

      % Terminal 2 Pier D/E Stands
      N_D1 = node(id: "STAND_D1" name: "Stand D1" kind: Types.NODE_STAND x: 800.0 y: 350.0 z: 101.0 code: Types.CODE_E)
      N_E2 = node(id: "STAND_E2" name: "Stand E2" kind: Types.NODE_STAND x: 950.0 y: 350.0 z: 101.0 code: Types.CODE_E)

      % Add Nodes to Graph
      G1 = {Graph.AddNode G0 N_07C}
      G2 = {Graph.AddNode G1 N_25C}
      G3 = {Graph.AddNode G2 N_07R}
      G4 = {Graph.AddNode G3 N_25L}
      G5 = {Graph.AddNode G4 N_18}
      G6 = {Graph.AddNode G5 N_18_END}
      G7 = {Graph.AddNode G6 N_07L}
      G8 = {Graph.AddNode G7 N_25R}
      G9 = {Graph.AddNode G8 N_A15}
      G10 = {Graph.AddNode G9 N_A20}
      G11 = {Graph.AddNode G10 N_Z15}
      G12 = {Graph.AddNode G11 N_Z25}
      G13 = {Graph.AddNode G12 N_D1}
      G14 = {Graph.AddNode G13 N_E2}

      % Primary Movement Edges
      E1 = edge(id: "E_18_ROLL" from: "NODE_18" to: "NODE_18_END" length: 4000.0 maxSpeed: 80.0 width: 45.0 radius: 5000.0 kind: Types.EDGE_RUNWAY_CENTERLINE active: true)
      E2 = edge(id: "E_Z15_TAXI" from: "STAND_Z15" to: "NODE_18" length: 2450.0 maxSpeed: 15.0 width: 25.0 radius: 80.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)
      E3 = edge(id: "E_25C_ROLL" from: "NODE_25C" to: "NODE_07C" length: 4000.0 maxSpeed: 80.0 width: 60.0 radius: 5000.0 kind: Types.EDGE_RUNWAY_CENTERLINE active: true)
      E4 = edge(id: "E_A15_25C" from: "STAND_A15" to: "NODE_25C" length: 1900.0 maxSpeed: 12.0 width: 23.0 radius: 50.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)

      G15 = {Graph.AddEdge G14 E1}
      G16 = {Graph.AddEdge G15 E2}
      G17 = {Graph.AddEdge G16 E3}
      G18 = {Graph.AddEdge G17 E4}
   in
      G18
   end

end
