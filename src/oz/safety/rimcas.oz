% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Safety.RIMCAS
% Description: Runway Incursion Monitoring and Conflict Alert System (RIMCAS),
%              time-to-collision (TTC) prediction, and A-SMGCS Stage 1/2 alert generation.
% =============================================================================

functor
export
   ALERT_STAGE_NONE: ALERT_STAGE_NONE
   ALERT_STAGE_CAUTION: ALERT_STAGE_CAUTION
   ALERT_STAGE_WARNING: ALERT_STAGE_WARNING
   EvaluateRunwayConflict: EvaluateRunwayConflict
   ComputeTimeToCollisionSec: ComputeTimeToCollisionSec
define

   ALERT_STAGE_NONE    = alert_none
   ALERT_STAGE_CAUTION = alert_caution  % Stage 1: Cautionary warning
   ALERT_STAGE_WARNING = alert_warning  % Stage 2: Critical incursion alert

   % --------------------------------------------------------------------------
   % Time to Collision (TTC): Evaluates closing velocity along runway centerline
   % --------------------------------------------------------------------------
   fun {ComputeTimeToCollisionSec PosX1 SpeedX1 PosX2 SpeedX2}
      RelDistance = PosX2 - PosX1
      AbsDistance = if RelDistance < 0.0 then ~RelDistance else RelDistance end
      ClosingSpeed = SpeedX1 - SpeedX2
   in
      if ClosingSpeed =< 0.0 then
         1e9 % Targets diverging or stationary relative to each other
      else
         AbsDistance / ClosingSpeed
      end
   end

   % --------------------------------------------------------------------------
   % EvaluateRunwayConflict: Monitors pairs of active runway targets
   % --------------------------------------------------------------------------
   fun {EvaluateRunwayConflict TargetLanding TargetCrossing RunwayCenterlineY ProtectedWidthMeters}
      LandingDistToCenter = TargetLanding.y - RunwayCenterlineY
      AbsLandingDist = if LandingDistToCenter < 0.0 then ~LandingDistToCenter else LandingDistToCenter end

      CrossingDistToCenter = TargetCrossing.y - RunwayCenterlineY
      AbsCrossingDist = if CrossingDistToCenter < 0.0 then ~CrossingDistToCenter else CrossingDistToCenter end
   in
      if AbsCrossingDist < ProtectedWidthMeters andthen AbsLandingDist < ProtectedWidthMeters then
         TTC = {ComputeTimeToCollisionSec TargetLanding.x TargetLanding.speedX TargetCrossing.x TargetCrossing.speedX}
      in
         if TTC < 15.0 then
            alert(stage: ALERT_STAGE_WARNING
                  target1: TargetLanding.callsign
                  target2: TargetCrossing.callsign
                  ttcSeconds: TTC
                  message: "CRITICAL: Imminent Runway Collision - Abort Landing / Vacate Runway")
         elseif TTC < 30.0 then
            alert(stage: ALERT_STAGE_CAUTION
                  target1: TargetLanding.callsign
                  target2: TargetCrossing.callsign
                  ttcSeconds: TTC
                  message: "CAUTION: Target Infringing Runway Protected Area")
         else
            alert(stage: ALERT_STAGE_NONE target1: none target2: none ttcSeconds: TTC message: "OK")
         end
      else
         alert(stage: ALERT_STAGE_NONE target1: none target2: none ttcSeconds: 1e9 message: "OK")
      end
   end

end
