% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.ConflictDetection
% Description: Spatial and temporal conflict detection predicates (head-on collision,
%              tailgating, intersection crossing, and jet blast hazard impingement).
% =============================================================================

functor
export
   DetectHeadOnConflict: DetectHeadOnConflict
   DetectTailgatingConflict: DetectTailgatingConflict
   DetectIntersectionConflict: DetectIntersectionConflict
   DetectJetBlastImpingement: DetectJetBlastImpingement
define

   % --------------------------------------------------------------------------
   % Head-On Conflict: Aircraft 1 and Aircraft 2 traverse opposite directions
   % of the same taxiway edge with overlapping time intervals.
   % --------------------------------------------------------------------------
   fun {DetectHeadOnConflict Traj1 Traj2}
      fun {HasOpposingSegments Segs1 Segs2}
         case Segs1
         of nil then false
         [] S1 | R1 then
            fun {CheckMatch List}
               case List
               of nil then false
               [] S2 | R2 then
                  % Opposing nodes: S1.from == S2.to and S1.to == S2.from
                  IsOpposing = (S1.from == S2.to) andthen (S1.to == S2.from)
                  TimeOverlaps = (S1.entryTime < S2.exitTime) andthen (S1.exitTime > S2.entryTime)
               in
                  if IsOpposing andthen TimeOverlaps then
                     true
                  else
                     {CheckMatch R2}
                  end
               end
            end
         in
            if {CheckMatch Segs2} then true else {HasOpposingSegments R1 Segs2} end
         end
      end
   in
      {HasOpposingSegments Traj1.segments Traj2.segments}
   end

   % --------------------------------------------------------------------------
   % Tailgating Conflict: Follower catches up to Leader on same edge with
   % gap < D_safe(v_lead, v_follow)
   % --------------------------------------------------------------------------
   fun {DetectTailgatingConflict S1 S2 SafeBufferSec}
      if S1.edgeId == S2.edgeId then
         TimeDiff = S2.entryTime - S1.entryTime
         AbsDiff = if TimeDiff < 0.0 then ~TimeDiff else TimeDiff end
      in
         AbsDiff < SafeBufferSec
      else
         false
      end
   end

   % --------------------------------------------------------------------------
   % Intersection Conflict: Two aircraft arrive at shared intersection node
   % within MinCrossingSeparationSec
   % --------------------------------------------------------------------------
   fun {DetectIntersectionConflict NodeArr1 NodeArr2 MinCrossingSeparationSec}
      if NodeArr1.nodeId == NodeArr2.nodeId then
         Diff = NodeArr1.arrivalTime - NodeArr2.arrivalTime
         AbsDiff = if Diff < 0.0 then ~Diff else Diff end
      in
         AbsDiff < MinCrossingSeparationSec
      else
         false
      end
   end

   % --------------------------------------------------------------------------
   % Jet Blast Impingement: Trailing aircraft within 150m behind widebody
   % applying breakaway thrust
   % --------------------------------------------------------------------------
   fun {DetectJetBlastImpingement LeaderCode LeaderThrustHigh DistanceMeters}
      IsWidebody = (LeaderCode == cat_a) orelse (LeaderCode == cat_b) orelse (LeaderCode == cat_c)
   in
      if IsWidebody andthen LeaderThrustHigh then
         DistanceMeters < 150.0
      else
         false
      end
   end

end
