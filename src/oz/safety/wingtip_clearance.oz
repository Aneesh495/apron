% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Safety.WingtipClearance
% Description: ICAO Annex 14 wingtip clearance envelopes, parallel taxiway separation,
%              and ground obstacle collision avoidance checks.
% =============================================================================

functor
export
   GetMinimumWingtipClearanceMeters: GetMinimumWingtipClearanceMeters
   IsParallelTaxiwaySeparationSafe: IsParallelTaxiwaySeparationSafe
   IsObstacleClearanceViolated: IsObstacleClearanceViolated
define

   % --------------------------------------------------------------------------
   % Minimum Wingtip Clearance to Fixed Obstacles (ICAO Annex 14 Table 3-1)
   % --------------------------------------------------------------------------
   fun {GetMinimumWingtipClearanceMeters AircraftCode}
      case AircraftCode
      of code_a then 3.0
      [] code_b then 4.5
      [] code_c then 4.5
      [] code_d then 7.5
      [] code_e then 7.5
      [] code_f then 10.5  % A380 requires 10.5m clearance to building/mast
      else 4.5
      end
   end

   % --------------------------------------------------------------------------
   % Parallel Taxiway Centerline-to-Centerline Minimum Separation
   % S >= (Wingspan1 + Wingspan2) / 2 + Buffer
   % --------------------------------------------------------------------------
   fun {IsParallelTaxiwaySeparationSafe CenterlineDistanceMeters Wingspan1 Wingspan2 AircraftCode1 AircraftCode2}
      RequiredBuffer = {GetMinimumWingtipClearanceMeters AircraftCode1} + {GetMinimumWingtipClearanceMeters AircraftCode2}
      MinimumSeparation = ((Wingspan1 + Wingspan2) / 2.0) + RequiredBuffer
   in
      CenterlineDistanceMeters >= MinimumSeparation
   end

   % --------------------------------------------------------------------------
   % Obstacle Clearance Violation Check
   % --------------------------------------------------------------------------
   fun {IsObstacleClearanceViolated LateralDistanceToObstacle AircraftWingspan AircraftCode}
      WingtipDistance = LateralDistanceToObstacle - (AircraftWingspan / 2.0)
      MinRequired = {GetMinimumWingtipClearanceMeters AircraftCode}
   in
      WingtipDistance < MinRequired
   end

end
