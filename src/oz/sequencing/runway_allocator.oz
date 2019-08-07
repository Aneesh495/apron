% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.RunwayAllocator
% Description: Multi-runway assignment, load balancing, stand-proximity heuristics,
%              and departure route pairing across complex aerodromes.
% =============================================================================

functor
export
   AllocateRunways: AllocateRunways
   ChooseBestRunwayForFlight: ChooseBestRunwayForFlight
define

   % --------------------------------------------------------------------------
   % ChooseBestRunwayForFlight: Selects optimal runway based on:
   % 1. Stand taxi distance
   % 2. SID departure heading alignment
   % 3. Current runway queue backlog
   % --------------------------------------------------------------------------
   fun {ChooseBestRunwayForFlight Flight CandidateRunways RunwayQueues}
      fun {ScoreRunway Rwy}
         % Stand alignment penalty
         StandY = Flight.standY
         RwyY   = Rwy.thresholdY
         DistY  = StandY - RwyY
         TaxiPenalty = (if DistY < 0.0 then ~DistY else DistY end) * 0.01

         % Route heading alignment penalty
         HdgDiff = Flight.sidHeadingDeg - Rwy.bearingDeg
         AbsHdgDiff = if HdgDiff < 0.0 then ~HdgDiff else HdgDiff end
         HeadingPenalty = AbsHdgDiff * 0.1

         % Current backlog queue penalty
         QueueCount = {GetQueueCount RunwayQueues Rwy.designator}
         QueuePenalty = {IntToFloat QueueCount} * 15.0
      in
         TaxiPenalty + HeadingPenalty + QueuePenalty
      end

      fun {FindMinCandidate Candidates BestRwy BestScore}
         case Candidates
         of nil then BestRwy
         [] R | Rest then
            Score = {ScoreRunway R}
         in
            if Score < BestScore then
               {FindMinCandidate Rest R Score}
            else
               {FindMinCandidate Rest BestRwy BestScore}
            end
         end
      end
   in
      {FindMinCandidate CandidateRunways none 1e12}
   end

   fun {GetQueueCount Queues RwyDesignator}
      case Queues
      of nil then 0
      [] pair(Desig Count) | Rest then
         if Desig == RwyDesignator then Count else {GetQueueCount Rest RwyDesignator} end
      end
   end

   % --------------------------------------------------------------------------
   % AllocateRunways: Assigns candidate runways across batch of flights
   % --------------------------------------------------------------------------
   fun {AllocateRunways Flights CandidateRunways}
      fun {AssignBatch List CurrentQueues}
         case List
         of nil then nil
         [] F | Rest then
            BestR = {ChooseBestRunwayForFlight F CandidateRunways CurrentQueues}
            UpdatedFlight = assigned(callsign: F.callsign
                                     runway: BestR.designator
                                     flight: F)
            % Increment queue count
            CurCount = {GetQueueCount CurrentQueues BestR.designator}
            NewQueues = pair(BestR.designator CurCount + 1) | CurrentQueues
         in
            UpdatedFlight | {AssignBatch Rest NewQueues}
         end
      end
   in
      {AssignBatch Flights nil}
   end

end
