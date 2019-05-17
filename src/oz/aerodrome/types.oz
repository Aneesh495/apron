% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Types
% Description: Physical aerodrome type classifications, ICAO Annex 14 Reference
%              Codes, surface coordinate systems, and movement area states.
% =============================================================================

functor
export
   % ICAO Aerodrome Reference Codes
   CODE_A: CODE_A
   CODE_B: CODE_B
   CODE_C: CODE_C
   CODE_D: CODE_D
   CODE_E: CODE_E
   CODE_F: CODE_F

   % Node Classifications
   NODE_STAND: NODE_STAND
   NODE_RUNWAY_THRESHOLD: NODE_RUNWAY_THRESHOLD
   NODE_RAPID_EXIT: NODE_RAPID_EXIT
   NODE_INTERSECTION: NODE_INTERSECTION
   NODE_HOLDING_POINT: NODE_HOLDING_POINT
   NODE_STOPBAR: NODE_STOPBAR
   NODE_DEICE_PAD: NODE_DEICE_PAD

   % Taxiway Edge Classifications
   EDGE_RUNWAY_CENTERLINE: EDGE_RUNWAY_CENTERLINE
   EDGE_RAPID_EXIT: EDGE_RAPID_EXIT
   EDGE_STANDARD_TAXIWAY: EDGE_STANDARD_TAXIWAY
   EDGE_APRON_TAXILANE: EDGE_APRON_TAXILANE
   EDGE_LEAD_IN_LINE: EDGE_LEAD_IN_LINE
   EDGE_PUSHBACK_TRACK: EDGE_PUSHBACK_TRACK

   % Surface Conditions
   SURF_DRY: SURF_DRY
   SURF_WET: SURF_WET
   SURF_CONTAMINATED: SURF_CONTAMINATED
   SURF_LVO_CAT_II: SURF_LVO_CAT_II
   SURF_LVO_CAT_III: SURF_LVO_CAT_III

   % Validation functions
   IsCodeCompatible: IsCodeCompatible
   GetMaxWingspanMeters: GetMaxWingspanMeters
   GetMaxOuterGearWheelSpanMeters: GetMaxOuterGearWheelSpanMeters
define

   % --------------------------------------------------------------------------
   % ICAO Annex 14 Aerodrome Reference Code Definitions
   % Code letter based on wingspan and outer main gear wheel span (OMGWS)
   % --------------------------------------------------------------------------
   CODE_A = code_a  % Wingspan < 15 m, OMGWS < 4.5 m (e.g. Cessna 172)
   CODE_B = code_b  % 15 m <= Wingspan < 24 m (e.g. King Air, CRJ-200)
   CODE_C = code_c  % 24 m <= Wingspan < 36 m (e.g. A320, B737)
   CODE_D = code_d  % 36 m <= Wingspan < 52 m (e.g. B757, B767)
   CODE_E = code_e  % 52 m <= Wingspan < 65 m (e.g. B777, B787, A350, A330)
   CODE_F = code_f  % 65 m <= Wingspan < 80 m (e.g. A380-800, B747-8)

   % --------------------------------------------------------------------------
   % Node Classifications
   % --------------------------------------------------------------------------
   NODE_STAND            = node_stand
   NODE_RUNWAY_THRESHOLD = node_runway_threshold
   NODE_RAPID_EXIT       = node_rapid_exit
   NODE_INTERSECTION     = node_intersection
   NODE_HOLDING_POINT    = node_holding_point
   NODE_STOPBAR          = node_stopbar
   NODE_DEICE_PAD        = node_deice_pad

   % --------------------------------------------------------------------------
   % Taxiway Edge Classifications
   % --------------------------------------------------------------------------
   EDGE_RUNWAY_CENTERLINE = edge_runway_centerline
   EDGE_RAPID_EXIT        = edge_rapid_exit
   EDGE_STANDARD_TAXIWAY  = edge_standard_taxiway
   EDGE_APRON_TAXILANE    = edge_apron_taxilane
   EDGE_LEAD_IN_LINE      = edge_lead_in_line
   EDGE_PUSHBACK_TRACK    = edge_pushback_track

   % --------------------------------------------------------------------------
   % Surface Operating Conditions
   % --------------------------------------------------------------------------
   SURF_DRY          = surf_dry
   SURF_WET          = surf_wet
   SURF_CONTAMINATED = surf_contaminated
   SURF_LVO_CAT_II   = surf_lvo_cat_ii
   SURF_LVO_CAT_III  = surf_lvo_cat_iii

   % --------------------------------------------------------------------------
   % Wingspan Upper Limits per ICAO Code
   % --------------------------------------------------------------------------
   fun {GetMaxWingspanMeters Code}
      case Code
      of code_a then 15.0
      [] code_b then 24.0
      [] code_c then 36.0
      [] code_d then 52.0
      [] code_e then 65.0
      [] code_f then 80.0
      else 36.0
      end
   end

   fun {GetMaxOuterGearWheelSpanMeters Code}
      case Code
      of code_a then 4.5
      [] code_b then 6.0
      [] code_c then 9.0
      [] code_d then 14.0
      [] code_e then 14.0
      [] code_f then 16.0
      else 9.0
      end
   end

   % --------------------------------------------------------------------------
   % Code Compatibility Predicate
   % Returns true if FacilityCode can accommodate AircraftCode
   % --------------------------------------------------------------------------
   fun {CodeRank Code}
      case Code
      of code_a then 1
      [] code_b then 2
      [] code_c then 3
      [] code_d then 4
      [] code_e then 5
      [] code_f then 6
      else 3
      end
   end

   fun {IsCodeCompatible FacilityCode AircraftCode}
      {CodeRank FacilityCode} >= {CodeRank AircraftCode}
   end

end
