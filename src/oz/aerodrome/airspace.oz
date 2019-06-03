% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Airspace
% Description: Terminal Maneuvering Area (TMA) arrival routes (STAR), departure
%              routes (SID), metering fixes, and holding stack allocations.
% =============================================================================

functor
export
   NewFix: NewFix
   NewStarRoute: NewStarRoute
   NewSidRoute: NewSidRoute
   ComputeSidDivergenceAngle: ComputeSidDivergenceAngle
   IsMeteringWindowFeasible: IsMeteringWindowFeasible
define

   % --------------------------------------------------------------------------
   % Navigation Fix Definition:
   % fix(name: String latDeg: Float lonDeg: Float minAltFt: Float maxSpeedKts: Float)
   % --------------------------------------------------------------------------

   fun {NewFix Name Lat Lon MinAlt MaxSpd}
      fix(name: Name
          latDeg: Lat
          lonDeg: Lon
          minAltFt: MinAlt
          maxSpeedKts: MaxSpd)
   end

   % --------------------------------------------------------------------------
   % STAR Definition (Standard Terminal Arrival Route):
   % star(name: String fixes: ListOfFixes targetRunway: String)
   % --------------------------------------------------------------------------
   fun {NewStarRoute Name Fixes TargetRwy}
      star(name: Name
           fixes: Fixes
           targetRunway: TargetRwy)
   end

   % --------------------------------------------------------------------------
   % SID Definition (Standard Instrument Departure):
   % sid(name: String
   %     departureRunway: String
   %     initialHeadingDeg: Float
   %     climbGradientPct: Float
   %     fixes: ListOfFixes)
   % --------------------------------------------------------------------------
   fun {NewSidRoute Name DepRwy InitHdg ClimbGrad Fixes}
      sid(name: Name
          departureRunway: DepRwy
          initialHeadingDeg: InitHdg
          climbGradientPct: ClimbGrad
          fixes: Fixes)
   end

   % --------------------------------------------------------------------------
   % Compute Initial Track Divergence Angle between two SIDs
   % SIDs diverging by >= 45 degrees permit reduced departure time separation
   % --------------------------------------------------------------------------
   fun {ComputeSidDivergenceAngle Sid1 Sid2}
      Diff = Sid1.initialHeadingDeg - Sid2.initialHeadingDeg
      AbsDiff = if Diff < 0.0 then ~Diff else Diff end
   in
      if AbsDiff > 180.0 then 360.0 - AbsDiff else AbsDiff end
   end

   fun {IsMeteringWindowFeasible EstimatedArrival ScheduledSlot BufferSeconds}
      Diff = EstimatedArrival - ScheduledSlot
      AbsDiff = if Diff < 0.0 then ~Diff else Diff end
   in
      AbsDiff =< BufferSeconds
   end

end
