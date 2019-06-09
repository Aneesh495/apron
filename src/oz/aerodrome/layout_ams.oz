% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.LayoutAMS
% Description: Detailed reference aerodrome topology for Amsterdam Schiphol (EHAM).
%              Six-runway tangential layout including 18R/36L (Polderbaan),
%              Kaagbaan, Aalsmeerbaan, Zwanenburgbaan, and Buitenveldertbaan.
% =============================================================================

functor
import
   Graph at 'graph.oz'
   Types at 'types.oz'
export
   BuildEHAM: BuildEHAM
define

   fun {BuildEHAM}
      G0 = {Graph.New}

      % Polderbaan (18R / 36L) - Remote Northwest Runway
      N_36L = node(id: "NODE_36L" name: "Polderbaan 36L" kind: Types.NODE_RUNWAY_THRESHOLD x: ~4800.0 y: 1200.0 z: ~3.0 code: Types.CODE_F)
      N_18R = node(id: "NODE_18R" name: "Polderbaan 18R" kind: Types.NODE_RUNWAY_THRESHOLD x: ~4800.0 y: 5000.0 z: ~3.0 code: Types.CODE_F)

      % Kaagbaan (06 / 24) - Main Southwest Runway
      N_06 = node(id: "NODE_06" name: "Kaagbaan 06" kind: Types.NODE_RUNWAY_THRESHOLD x: ~2800.0 y: ~2200.0 z: ~3.0 code: Types.CODE_F)
      N_24 = node(id: "NODE_24" name: "Kaagbaan 24" kind: Types.NODE_RUNWAY_THRESHOLD x: 500.0 y: ~500.0 z: ~3.0 code: Types.CODE_F)

      % Zwanenburgbaan (18C / 36C)
      N_18C = node(id: "NODE_18C" name: "Zwanenburgbaan 18C" kind: Types.NODE_RUNWAY_THRESHOLD x: ~1800.0 y: 3200.0 z: ~3.0 code: Types.CODE_E)
      N_36C = node(id: "NODE_36C" name: "Zwanenburgbaan 36C" kind: Types.NODE_RUNWAY_THRESHOLD x: ~1800.0 y: 200.0 z: ~3.0 code: Types.CODE_E)

      % Aalsmeerbaan (18L / 36R)
      N_18L = node(id: "NODE_18L" name: "Aalsmeerbaan 18L" kind: Types.NODE_RUNWAY_THRESHOLD x: 800.0 y: 1500.0 z: ~3.0 code: Types.CODE_E)
      N_36R = node(id: "NODE_36R" name: "Aalsmeerbaan 36R" kind: Types.NODE_RUNWAY_THRESHOLD x: 800.0 y: ~1800.0 z: ~3.0 code: Types.CODE_E)

      % Buitenveldertbaan (09 / 27)
      N_09 = node(id: "NODE_09" name: "Buitenveldertbaan 09" kind: Types.NODE_RUNWAY_THRESHOLD x: ~1200.0 y: 1800.0 z: ~3.0 code: Types.CODE_E)
      N_27 = node(id: "NODE_27" name: "Buitenveldertbaan 27" kind: Types.NODE_RUNWAY_THRESHOLD x: 2200.0 y: 1800.0 z: ~3.0 code: Types.CODE_E)

      % Terminal Pier D/E/F/G Stands (KLM Royal Dutch Airlines Hub)
      N_D10 = node(id: "STAND_D10" name: "Pier D Stand 10" kind: Types.NODE_STAND x: ~200.0 y: 200.0 z: ~3.0 code: Types.CODE_D)
      N_E4  = node(id: "STAND_E4"  name: "Pier E Stand 4"  kind: Types.NODE_STAND x: 100.0 y: ~100.0 z: ~3.0 code: Types.CODE_E)
      N_F5  = node(id: "STAND_F5"  name: "Pier F Stand 5"  kind: Types.NODE_STAND x: 300.0 y: ~200.0 z: ~3.0 code: Types.CODE_F)
      N_G3  = node(id: "STAND_G3"  name: "Pier G Stand 3"  kind: Types.NODE_STAND x: 500.0 y: ~300.0 z: ~3.0 code: Types.CODE_F)

      % Polderbaan Taxiway Bridge Node over A5 Motorway
      N_POLDER_BRIDGE = node(id: "NODE_BRIDGE_A5" name: "Polderbaan Taxiway Bridge Q" kind: Types.NODE_INTERSECTION x: ~3500.0 y: 1200.0 z: 2.0 code: Types.CODE_F)

      G1 = {Graph.AddNode G0 N_36L}
      G2 = {Graph.AddNode G1 N_18R}
      G3 = {Graph.AddNode G2 N_06}
      G4 = {Graph.AddNode G3 N_24}
      G5 = {Graph.AddNode G4 N_18C}
      G6 = {Graph.AddNode G5 N_36C}
      G7 = {Graph.AddNode G6 N_18L}
      G8 = {Graph.AddNode G7 N_36R}
      G9 = {Graph.AddNode G8 N_09}
      G10 = {Graph.AddNode G9 N_27}
      G11 = {Graph.AddNode G10 N_D10}
      G12 = {Graph.AddNode G11 N_E4}
      G13 = {Graph.AddNode G12 N_F5}
      G14 = {Graph.AddNode G13 N_G3}
      G15 = {Graph.AddNode G14 N_POLDER_BRIDGE}

      % Long Taxiway Victor / Quebec to Polderbaan (typically 4.5 km distance, 15 min taxi)
      E1 = edge(id: "E_CENTRAL_BRIDGE" from: "STAND_E4" to: "NODE_BRIDGE_A5" length: 3600.0 maxSpeed: 15.0 width: 25.0 radius: 100.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)
      E2 = edge(id: "E_BRIDGE_36L" from: "NODE_BRIDGE_A5" to: "NODE_36L" length: 1300.0 maxSpeed: 15.0 width: 25.0 radius: 80.0 kind: Types.EDGE_STANDARD_TAXIWAY active: true)
      E3 = edge(id: "E_36L_ROLL" from: "NODE_36L" to: "NODE_18R" length: 3800.0 maxSpeed: 80.0 width: 60.0 radius: 5000.0 kind: Types.EDGE_RUNWAY_CENTERLINE active: true)

      G16 = {Graph.AddEdge G15 E1}
      G17 = {Graph.AddEdge G16 E2}
      G18 = {Graph.AddEdge G17 E3}
   in
      G18
   end

end
