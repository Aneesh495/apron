% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.DelayEvaluator
% Description: Multi-criteria runway schedule evaluator computing total system delay,
%              makespan, A15 punctuality, and airline equity fairness indices.
% =============================================================================

functor
export
   ComputeScheduleMetrics: ComputeScheduleMetrics
   ComputeJainsFairnessIndex: ComputeJainsFairnessIndex
define

   % --------------------------------------------------------------------------
   % ComputeScheduleMetrics: Evaluates makespan, total delay, and A15 punctuality
   % --------------------------------------------------------------------------
   fun {ComputeScheduleMetrics Flights}
      fun {Analyze List MinT MaxT TotalDelay OnTimeCount TotalCount}
         case List
         of nil then
            Makespan = if MaxT > MinT then MaxT - MinT else 0.0 end
            AvgDelay = if TotalCount > 0 then TotalDelay / {IntToFloat TotalCount} else 0.0 end
            PunctualityPct = if TotalCount > 0 then ({IntToFloat OnTimeCount} / {IntToFloat TotalCount}) * 100.0 else 100.0 end
         in
            metrics(totalMovements: TotalCount
                    makespanSeconds: Makespan
                    totalDelayMinutes: TotalDelay / 60.0
                    averageDelayMinutes: AvgDelay / 60.0
                    punctualityA15Pct: PunctualityPct)
         [] F | Rest then
            ActualTakeoff = F.ttot
            ScheduledTakeoff = F.sobt + F.exot
            Delay = if ActualTakeoff > ScheduledTakeoff then ActualTakeoff - ScheduledTakeoff else 0.0 end

            NewMin = if ActualTakeoff < MinT then ActualTakeoff else MinT end
            NewMax = if ActualTakeoff > MaxT then ActualTakeoff else MaxT end
            IsA15 = Delay =< 900.0 % within 15 minutes
            NewOnTime = if IsA15 then OnTimeCount + 1 else OnTimeCount end
         in
            {Analyze Rest NewMin NewMax TotalDelay + Delay NewOnTime TotalCount + 1}
         end
      end
   in
      {Analyze Flights 1e12 0.0 0.0 0 0}
   end

   % --------------------------------------------------------------------------
   % Jain's Fairness Index: J = (sum x_i)^2 / (n * sum x_i^2)
   % Values range from 1/n (worst case unfairness) to 1.0 (perfect equity)
   % --------------------------------------------------------------------------
   fun {ComputeJainsFairnessIndex DelayList}
      Len = {Length DelayList}
   in
      if Len =< 1 then
         1.0
      else
         fun {Sums List SumX SumX2}
            case List
            of nil then pair(SumX SumX2)
            [] X | Rest then
               {Sums Rest SumX + X SumX2 + (X * X)}
            end
         end
         case {Sums DelayList 0.0 0.0}
         of pair(SX SX2) then
            if SX2 < 1e-6 then
               1.0 % All zero delay, perfectly fair
            else
               (SX * SX) / ({IntToFloat Len} * SX2)
            end
         end
      end
   end

end
