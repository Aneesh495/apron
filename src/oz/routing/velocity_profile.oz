% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.VelocityProfile
% Description: Aircraft longitudinal surface kinematics, rolling resistance,
%              curve negotiation limits, and dynamic jet blast hazard envelopes.
% =============================================================================

functor
import
   Math
export
   ComputeSafeTurnSpeed: ComputeSafeTurnSpeed
   ComputeDecelerationDistance: ComputeDecelerationDistance
   GetJetBlastHazardZone: GetJetBlastHazardZone
define

   % --------------------------------------------------------------------------
   % ComputeSafeTurnSpeed: Speed limit ensuring passenger lateral comfort (a <= 1.5 m/s^2)
   % --------------------------------------------------------------------------
   fun {ComputeSafeTurnSpeed TurnRadiusMeters}
      if TurnRadiusMeters >= 400.0 then
         15.0  % Straight speed limit (approx 30 kt)
      else
         {Math.sqrt TurnRadiusMeters * 1.47}
      end
   end

   % --------------------------------------------------------------------------
   % ComputeDecelerationDistance: Distance to brake from V1 to V2 at deceleration rate A
   % d = (V1^2 - V2^2) / (2 * A)
   % --------------------------------------------------------------------------
   fun {ComputeDecelerationDistance V1 V2 DecelRateMps2}
      if V1 =< V2 then
         0.0
      else
         ((V1 * V1) - (V2 * V2)) / (2.0 * DecelRateMps2)
      end
   end

   % --------------------------------------------------------------------------
   % GetJetBlastHazardZone: Computes length and width of danger envelope behind aircraft
   % --------------------------------------------------------------------------
   fun {GetJetBlastHazardZone AircraftCategory ThrustSetting}
      BaseLength = case AircraftCategory
                   of cat_a then 180.0  % A380
                   [] cat_b then 150.0  % B777
                   [] cat_c then 120.0  % B787
                   [] cat_d then 80.0   % A320
                   else 50.0
                   end
      ThrustMultiplier = case ThrustSetting
                         of idle then 1.0
                         [] breakaway then 2.0  % 70-80% N1 to initiate taxi
                         [] takeoff_roll then 3.0
                         else 1.0
                         end
      HazardLength = BaseLength * ThrustMultiplier
      HazardWidth  = 30.0 + (HazardLength * 0.15) % spreading cone
   in
      hazard(lengthMeters: HazardLength widthMeters: HazardWidth)
   end

end
