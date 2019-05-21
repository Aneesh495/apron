% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Runway
% Description: Runway physical geometry, declared distances (TORA, TODA, ASDA, LDA),
%              ILS glideslope intercepts, and mixed-mode operating configurations.
% =============================================================================

functor
export
   NewRunway: NewRunway
   GetDeclaredDistances: GetDeclaredDistances
   IsApproachCompatible: IsApproachCompatible
   GetRapidExits: GetRapidExits
   ComputeRunwayOccupancyTime: ComputeRunwayOccupancyTime
define

   % --------------------------------------------------------------------------
   % Runway Record Structure:
   % runway(designator: String
   %        tora: Meters      % Take-Off Run Available
   %        toda: Meters      % Take-Off Distance Available
   %        asda: Meters      % Accelerate-Stop Distance Available
   %        lda: Meters       % Landing Distance Available
   %        width: Meters
   %        bearingDeg: Float
   %        thresholdX: Float
   %        thresholdY: Float
   %        thresholdAlt: Float
   %        glideSlopeDeg: Float
   %        rapidExits: ListOfExits)
   % --------------------------------------------------------------------------

   fun {NewRunway Designator Tora Toda Asda Lda Width Bearing ThreshX ThreshY Alt GS Exits}
      runway(designator: Designator
             tora: Tora
             toda: Toda
             asda: Asda
             lda: Lda
             width: Width
             bearingDeg: Bearing
             thresholdX: ThreshX
             thresholdY: ThreshY
             thresholdAlt: Alt
             glideSlopeDeg: GS
             rapidExits: Exits)
   end

   fun {GetDeclaredDistances R}
      declared(tora: R.tora
               toda: R.toda
               asda: R.asda
               lda: R.lda)
   end

   % --------------------------------------------------------------------------
   % Approach Compatibility: Verifies required landing distance vs LDA
   % --------------------------------------------------------------------------
   fun {IsApproachCompatible R RequiredLandingDist}
      R.lda >= RequiredLandingDist
   end

   fun {GetRapidExits R}
      R.rapidExits
   end

   % --------------------------------------------------------------------------
   % Runway Occupancy Time (ROT) Estimation
   % Computes nominal time from threshold crossing to vacating runway
   % --------------------------------------------------------------------------
   fun {ComputeRunwayOccupancyTime R AircraftCategory SurfaceCondition}
      BaseROT = case AircraftCategory
                of code_f then 65.0  % A380 requires longer deceleration
                [] code_e then 55.0  % B777 / A350
                [] code_d then 50.0  % B757 / B767
                [] code_c then 45.0  % A320 / B737
                [] code_b then 40.0
                [] code_a then 35.0
                else 50.0
                end
      Multiplier = case SurfaceCondition
                   of surf_dry then 1.0
                   [] surf_wet then 1.15
                   [] surf_contaminated then 1.35
                   else 1.0
                   end
   in
      BaseROT * Multiplier
   end

end
