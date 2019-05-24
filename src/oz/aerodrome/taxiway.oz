% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Taxiway
% Description: Taxiway kinematics, maximum cornering speeds, lateral acceleration
%              limits, and segment traversal transit time computations.
% =============================================================================

functor
import
   Math
export
   NewTaxiwaySegment: NewTaxiwaySegment
   ComputeMaxCorneringSpeed: ComputeMaxCorneringSpeed
   ComputeSegmentTransitTime: ComputeSegmentTransitTime
   IsOverweightPermitted: IsOverweightPermitted
define

   G_ACCEL = 9.80665
   MAX_LATERAL_COMFORT_ACCEL = 1.47  % m/s^2 (~0.15 g)

   % --------------------------------------------------------------------------
   % Taxiway Segment Structure:
   % taxiway(id: Id
   %         name: String
   %         fromNode: Id
   %         toNode: Id
   %         lengthMeters: Float
   %         baseSpeedLimitMps: Float
   %         turnRadiusMeters: Float
   %         maxPcn: Float           % Pavement Classification Number
   %         wingspanLimitMeters: Float)
   % --------------------------------------------------------------------------

   fun {NewTaxiwaySegment Id Name FromNode ToNode Len SpeedLimit Radius Pcn Wingspan}
      taxiway(id: Id
              name: Name
              fromNode: FromNode
              toNode: ToNode
              lengthMeters: Len
              baseSpeedLimitMps: SpeedLimit
              turnRadiusMeters: Radius
              maxPcn: Pcn
              wingspanLimitMeters: Wingspan)
   end

   % --------------------------------------------------------------------------
   % Cornering Speed Limit: v = sqrt(R * a_lat)
   % --------------------------------------------------------------------------
   fun {ComputeMaxCorneringSpeed RadiusMeters BaseLimitMps}
      if RadiusMeters > 500.0 then
         BaseLimitMps
      else
         CorneringLimit = {Math.sqrt RadiusMeters * MAX_LATERAL_COMFORT_ACCEL}
      in
         if CorneringLimit < BaseLimitMps then
            CorneringLimit
         else
            BaseLimitMps
         end
      end
   end

   % --------------------------------------------------------------------------
   % Segment Transit Time Calculation:
   % Models trapezoidal velocity profile with acceleration A_accel = 0.8 m/s^2
   % and deceleration A_decel = 1.2 m/s^2
   % --------------------------------------------------------------------------
   fun {ComputeSegmentTransitTime Segment EntrySpeed ExitSpeed}
      MaxSpeed = {ComputeMaxCorneringSpeed Segment.turnRadiusMeters Segment.baseSpeedLimitMps}
      Distance = Segment.lengthMeters

      A_acc = 0.8
      A_dec = 1.2

      % Time to accelerate from EntrySpeed to MaxSpeed
      T_acc = if EntrySpeed < MaxSpeed then (MaxSpeed - EntrySpeed) / A_acc else 0.0 end
      D_acc = (EntrySpeed * T_acc) + (0.5 * A_acc * T_acc * T_acc)

      % Time to decelerate from MaxSpeed to ExitSpeed
      T_dec = if ExitSpeed < MaxSpeed then (MaxSpeed - ExitSpeed) / A_dec else 0.0 end
      D_dec = (MaxSpeed * T_dec) - (0.5 * A_dec * T_dec * T_dec)
   in
      if D_acc + D_dec =< Distance then
         % Full cruise plateau reached
         D_cruise = Distance - (D_acc + D_dec)
         T_cruise = D_cruise / MaxSpeed
      in
         T_acc + T_cruise + T_dec
      else
         % Triangular velocity profile (segment too short for full cruise)
         AvgSpeed = (EntrySpeed + ExitSpeed) / 2.0
         EffectiveSpeed = if AvgSpeed < 3.0 then 3.0 else AvgSpeed end
      in
         Distance / EffectiveSpeed
      end
   end

   % --------------------------------------------------------------------------
   % Pavement Bearing Strength (ACN / PCN method)
   % Returns true if aircraft AircraftAcn <= pavement PCN
   % --------------------------------------------------------------------------
   fun {IsOverweightPermitted Segment AircraftAcn}
      AircraftAcn =< Segment.maxPcn
   end

end
