% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.SidDivergence
% Description: Standard Instrument Departure (SID) route divergence geometry,
%              air traffic route spacing, and speed catch-up buffer calculations.
% =============================================================================

functor
import
   WakeMatrix at 'wake_matrix.oz'
export
   ComputeDepartureSpacing: ComputeDepartureSpacing
   GetSidTrackDivergence: GetSidTrackDivergence
define

   % --------------------------------------------------------------------------
   % Calculate initial heading divergence between two SIDs [0, 180]
   % --------------------------------------------------------------------------
   fun {GetSidTrackDivergence Hdg1 Hdg2}
      Diff = Hdg1 - Hdg2
      AbsDiff = if Diff < 0.0 then ~Diff else Diff end
   in
      if AbsDiff > 180.0 then 360.0 - AbsDiff else AbsDiff end
   end

   % --------------------------------------------------------------------------
   % ComputeDepartureSpacing: Combines wake vortex separation with route divergence
   % Spacing = max(WakeSeparationSeconds, RouteSeparationSeconds + CatchUpBuffer)
   % --------------------------------------------------------------------------
   fun {ComputeDepartureSpacing LeaderRecat FollowerRecat LeaderHdg FollowerHdg LeaderSpd FollowerSpd}
      WakeSepSec = {WakeMatrix.GetDepartureSeparationSeconds LeaderRecat FollowerRecat}
      Divergence = {GetSidTrackDivergence LeaderHdg FollowerHdg}

      RouteSepSec = if Divergence >= 45.0 then
                       60.0   % Divergent routes: minimum 1 minute
                    elseif Divergence >= 15.0 then
                       90.0   % Minor divergence: 1.5 minutes
                    else
                       120.0  % Identical / converging tracks: 2 minutes
                    end

      % Catch-up buffer if follower is significantly faster than leader on same route
      CatchUpSec = if Divergence < 15.0 andthen FollowerSpd > LeaderSpd then
                      (FollowerSpd - LeaderSpd) * 0.5
                   else
                      0.0
                   end

      EffectiveRouteSep = RouteSepSec + CatchUpSec
   in
      if WakeSepSec > EffectiveRouteSep then
         WakeSepSec
      else
         EffectiveRouteSep
      end
   end

end
