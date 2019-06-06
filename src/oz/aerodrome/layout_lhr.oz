% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.LayoutLHR
% Description: Detailed reference aerodrome topology for London Heathrow Airport (EGLL).
%              Dual parallel segregated/mixed runways 09L/27R and 09R/27L, Terminals 2-5.
% =============================================================================

functor
import
   Graph at 'graph.oz'
   Runway at 'runway.oz'
   Stand at 'stand.oz'
   DeicePad at 'deice_pad.oz'
   HoldingPoint at 'holding_point.oz'
   Types at 'types.oz'
export
   BuildEGLL: BuildEGLL
define

   fun {BuildEGLL}
      G0 = {Graph.New}

      % Runway 27R / 09L Thresholds and Nodes
      N_09L = node(id: "NODE_09L" name: "Threshold 09L" kind: Types.NODE_RUNWAY_THRESHOLD x: ~1850.0 y: 750.0 z: 24.0 code: Types.CODE_F)
      N_27R = node(id: "NODE_27R" name: "Threshold 27R" kind: Types.NODE_RUNWAY_THRESHOLD x: 2050.0 y: 750.0 z: 24.0 code: Types.CODE_F)

      % Runway 27L / 09R Thresholds and Nodes
      N_09R = node(id: "NODE_09R" name: "Threshold 09R" kind: Types.NODE_RUNWAY_THRESHOLD x: ~1650.0 y: ~650.0 z: 23.0 code: Types.CODE_F)
      N_27L = node(id: "NODE_27L" name: "Threshold 27L" kind: Types.NODE_RUNWAY_THRESHOLD x: 2010.0 y: ~650.0 z: 23.0 code: Types.CODE_F)

      % Holding Points
      N_A1 = node(id: "HP_A1" name: "Holding Point Alpha 1" kind: Types.NODE_HOLDING_POINT x: 1950.0 y: 840.0 z: 24.0 code: Types.CODE_F)
      N_B1 = node(id: "HP_B1" name: "Holding Point Bravo 1" kind: Types.NODE_HOLDING_POINT x: 1950.0 y: ~740.0 z: 23.0 code: Types.CODE_F)
      N_N1 = node(id: "HP_N1" name: "Holding Point November 1" kind: Types.NODE_HOLDING_POINT x: ~1750.0 y: 840.0 z: 24.0 code: Types.CODE_F)
      N_S1 = node(id: "HP_S1" name: "Holding Point Sierra 1" kind: Types.NODE_HOLDING_POINT x: ~1550.0 y: ~740.0 z: 23.0 code: Types.CODE_F)

      % Terminal 5 Stands
      N_S501 = node(id: "STAND_501" name: "Terminal 5 Stand 501" kind: Types.NODE_STAND x: ~1200.0 y: 200.0 z: 25.0 code: Types.CODE_E)
      N_S502 = node(id: "STAND_502" name: "Terminal 5 Stand 502" kind: Types.NODE_STAND x: ~1150.0 y: 200.0 z: 25.0 code: Types.CODE_E)
      N_S503 = node(id: "STAND_503" name: "Terminal 5 Stand 503" kind: Types.NODE_STAND x: ~1100.0 y: 200.0 z: 25.0 code: Types.CODE_F)
      N_S504 = node(id: "STAND_504" name: "Terminal 5 Stand 504" kind: Types.NODE_STAND x: ~1050.0 y: 200.0 z: 25.0 code: Types.CODE_F)

      % Terminal 2/3 Central Stands
      N_S201 = node(id: "STAND_201" name: "Terminal 2 Stand 201" kind: Types.NODE_STAND x: 400.0 y: 150.0 z: 24.0 code: Types.CODE_C)
      N_S202 = node(id: "STAND_202" name: "Terminal 2 Stand 202" kind: Types.NODE_STAND x: 450.0 y: 150.0 z: 24.0 code: Types.CODE_C)
      N_S301 = node(id: "STAND_301" name: "Terminal 3 Stand 301" kind: Types.NODE_STAND x: 100.0 y: 300.0 z: 24.0 code: Types.CODE_E)
      N_S302 = node(id: "STAND_302" name: "Terminal 3 Stand 302" kind: Types.NODE_STAND x: 150.0 y: 300.0 z: 24.0 code: Types.CODE_E)

      % Rapid Exit Taxiways
      N_RET_N4 = node(id: "RET_N4" name: "Rapid Exit N4 (27R)" kind: Types.NODE_RAPID_EXIT x: 600.0 y: 750.0 z: 24.0 code: Types.CODE_F)
      N_RET_S4 = node(id: "RET_S4" name: "Rapid Exit S4 (27L)" kind: Types.NODE_RAPID_EXIT x: 500.0 y: ~650.0 z: 23.0 code: Types.CODE_F)

      % Central De-icing Pad
      N_DEICE_J = node(id: "DEICE_J" name: "J-Apron Remote De-icing" kind: Types.NODE_DEICE_PAD x: ~800.0 y: 550.0 z: 24.0 code: Types.CODE_F)

      % Add all nodes
      G1 = {Graph.AddNode G0 N_09L}
      G2 = {Graph.AddNode G1 N_27R}
      G3 = {Graph.AddNode G2 N_09R}
      G4 = {Graph.AddNode G3 N_27L}
      G5 = {Graph.AddNode G4 N_A1}
      G6 = {Graph.AddNode G5 N_B1}
      G7 = {Graph.AddNode G6 N_N1}
      G8 = {Graph.AddNode G7 N_S1}
      G9 = {Graph.AddNode G8 N_S501}
      G10 = {Graph.AddNode G9 N_S502}
      G11 = {Graph.AddNode G10 N_S503}
      G12 = {Graph.AddNode G11 N_S504}
      G13 = {Graph.AddNode G12 N_S201}
      G14 = {Graph.AddNode G13 N_S202}
      G15 = {Graph.AddNode G14 N_S301}
      G16 = {Graph.AddNode G15 N_S302}
      G17 = {Graph.AddNode G16 N_RET_N4}
      G18 = {Graph.AddNode G17 N_RET_S4}
      G19 = {Graph.AddNode G18 N_DEICE_J}

      % Connect primary taxiway edges
      E1 = edge(id: "E_A1_27R" from: "HP_A1" to: "NODE_27R" length: 150.0 maxSpeed: 10.0 width: 25.0 radius: 45.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)
      E2 = edge(id: "E_B1_27L" from: "HP_B1" to: "NODE_27L" length: 140.0 maxSpeed: 10.0 width: 25.0 radius: 45.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)
      E3 = edge(id: "E_27R_N4" from: "NODE_27R" to: "RET_N4" length: 1450.0 maxSpeed: 50.0 width: 30.0 radius: 800.0 kind: Types.EDGE_RAPID_EXIT active: true)
      E4 = edge(id: "E_27L_S4" from: "NODE_27L" to: "RET_S4" length: 1510.0 maxSpeed: 50.0 width: 30.0 radius: 800.0 kind: Types.EDGE_RAPID_EXIT active: true)
      E5 = edge(id: "E_504_PUSH" from: "STAND_504" to: "DEICE_J" length: 420.0 maxSpeed: 8.0 width: 23.0 radius: 35.0 kind: Types.EDGE_PUSHBACK_TRACK active: true)
      E6 = edge(id: "E_DEICE_A1" from: "DEICE_J" to: "HP_A1" length: 2800.0 maxSpeed: 15.0 width: 25.0 radius: 100.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)

      G20 = {Graph.AddEdge G19 E1}
      G21 = {Graph.AddEdge G20 E2}
      G22 = {Graph.AddEdge G21 E3}
      G23 = {Graph.AddEdge G22 E4}
      G24 = {Graph.AddEdge G23 E5}
      G25 = {Graph.AddEdge G24 E6}
   in
      G25
   end

end
