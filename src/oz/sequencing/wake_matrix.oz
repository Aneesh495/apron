% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.WakeMatrix
% Description: RECAT-EU 6x6 pairwise wake separation matrices for approach radar
%              distance (nautical miles) and departure runway roll (seconds).
% =============================================================================

functor
import
   RecatEU at 'recat_eu.oz'
export
   GetApproachSeparationNM: GetApproachSeparationNM
   GetDepartureSeparationSeconds: GetDepartureSeparationSeconds
   GetSeparationTimeAtSpeed: GetSeparationTimeAtSpeed
define

   % --------------------------------------------------------------------------
   % RECAT-EU Final Approach Distance Separation Matrix (Nautical Miles)
   % Rows: Leader (CAT-A to CAT-F)
   % Cols: Follower (CAT-A to CAT-F)
   % --------------------------------------------------------------------------
   ApproachMatrix = [
      %           CAT-A CAT-B CAT-C CAT-D CAT-E CAT-F
      /* CAT-A */ [3.0   4.0   5.0   5.0   6.0   8.0]
      /* CAT-B */ [3.0   3.0   4.0   4.0   5.0   7.0]
      /* CAT-C */ [3.0   3.0   3.0   3.0   4.0   6.0]
      /* CAT-D */ [3.0   3.0   3.0   3.0   3.0   5.0]
      /* CAT-E */ [3.0   3.0   3.0   3.0   3.0   4.0]
      /* CAT-F */ [3.0   3.0   3.0   3.0   3.0   3.0]
   ]

   % --------------------------------------------------------------------------
   % RECAT-EU Departure Time Separation Matrix (Seconds)
   % Rows: Leader
   % Cols: Follower
   % --------------------------------------------------------------------------
   DepartureMatrix = [
      %           CAT-A CAT-B CAT-C CAT-D CAT-E CAT-F
      /* CAT-A */ [100.0 120.0 140.0 160.0 180.0 200.0]
      /* CAT-B */ [90.0  100.0 120.0 120.0 140.0 160.0]
      /* CAT-C */ [80.0  80.0  90.0  100.0 120.0 140.0]
      /* CAT-D */ [70.0  70.0  70.0  80.0  100.0 120.0]
      /* CAT-E */ [60.0  60.0  60.0  60.0  80.0  100.0]
      /* CAT-F */ [60.0  60.0  60.0  60.0  60.0  80.0]
   ]

   fun {CategoryToIndex Cat}
      case Cat
      of cat_a then 1
      [] cat_b then 2
      [] cat_c then 3
      [] cat_d then 4
      [] cat_e then 5
      [] cat_f then 6
      else 4
      end
   end

   fun {GetApproachSeparationNM LeaderCat FollowerCat}
      R = {CategoryToIndex LeaderCat}
      C = {CategoryToIndex FollowerCat}
      Row = {Nth ApproachMatrix R}
   in
      {Nth Row C}
   end

   fun {GetDepartureSeparationSeconds LeaderCat FollowerCat}
      R = {CategoryToIndex LeaderCat}
      C = {CategoryToIndex FollowerCat}
      Row = {Nth DepartureMatrix R}
   in
      {Nth Row C}
   end

   % --------------------------------------------------------------------------
   % Time-Based Separation (TBS): Converts distance separation into seconds
   % given the follower's final approach ground speed (knots)
   % Time (sec) = (Distance (NM) / GroundSpeed (kt)) * 3600
   % --------------------------------------------------------------------------
   fun {GetSeparationTimeAtSpeed LeaderCat FollowerCat FollowerGroundSpeedKnots}
      DistNM = {GetApproachSeparationNM LeaderCat FollowerCat}
      Speed = if FollowerGroundSpeedKnots < 80.0 then 130.0 else FollowerGroundSpeedKnots end
   in
      (DistNM / Speed) * 3600.0
   end

end
