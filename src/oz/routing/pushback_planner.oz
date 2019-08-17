% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.PushbackPlanner
% Description: Kinematic pushback maneuver trajectory generation, nose/tail turn
%              orientations, and tow-tug apron return routing algorithms.
% =============================================================================

functor
export
   PlanPushbackManeuver: PlanPushbackManeuver
   GetTowTugReturnTransitTime: GetTowTugReturnTransitTime
define

   % --------------------------------------------------------------------------
   % PlanPushbackManeuver: Generates kinematic phases for aircraft pushback
   % --------------------------------------------------------------------------
   fun {PlanPushbackManeuver StandId ReleaseNodeId FacingDirection StartTime PushDurationSec}
      Phase1_Hookup     = phase(name: "Tug Coupling & Chocks Away" duration: 60.0)
      Phase2_Reverse    = phase(name: "Straight Reverse Roll" duration: PushDurationSec * 0.4)
      Phase3_Turn       = phase(name: "Tail Turn" facing: FacingDirection duration: PushDurationSec * 0.4)
      Phase4_Disconnect = phase(name: "Towbar Disconnect & Pin Check" duration: 60.0)

      TotalDuration = 60.0 + (PushDurationSec * 0.8) + 60.0
      EndTime = StartTime + TotalDuration
   in
      maneuver(stand: StandId
               releasePoint: ReleaseNodeId
               facingDirection: FacingDirection
               startTime: StartTime
               endTime: EndTime
               totalDurationSec: TotalDuration
               phases: [Phase1_Hookup Phase2_Reverse Phase3_Turn Phase4_Disconnect])
   end

   % --------------------------------------------------------------------------
   % Tow-Tug Return Transit Time: Tow tug travels along apron service road at 5 m/s
   % --------------------------------------------------------------------------
   fun {GetTowTugReturnTransitTime ServiceRoadDistanceMeters}
      ServiceRoadDistanceMeters / 5.0
   end

end
