% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.DepartureStream
% Description: Departure Manager (DMAN) departure metering, runway roll spacing,
%              and Target Take-Off Time (TTOT) allocation.
% =============================================================================

functor
import
   SidDivergence at 'sid_divergence.oz'
   ListExt at '../core/list_ext.oz'
export
   SequenceDepartureStream: SequenceDepartureStream
   EvaluateTotalDepartureDelay: EvaluateTotalDepartureDelay
define

   % --------------------------------------------------------------------------
   % SequenceDepartureStream: Schedules consecutive departures on a single runway
   % --------------------------------------------------------------------------
   fun {SequenceDepartureStream Departures}
      % Sort by earliest runway availability: TOBT + EXOT
      Sorted = {ListExt.SortWith Departures
                fun {$ A B} (A.tobt + A.exot) =< (B.tobt + B.exot) end}

      fun {ScheduleQueue Queue LastRollTime LastRecat LastHdg LastSpd}
         case Queue
         of nil then nil
         [] D | Rest then
            EarliestStart = D.tobt + D.exot
            RequiredSpacing = if LastRollTime =< 0.0 then
                                 0.0
                              else
                                 {SidDivergence.ComputeDepartureSpacing LastRecat
                                                                        D.recatCategory
                                                                        LastHdg
                                                                        D.initialHeadingDeg
                                                                        LastSpd
                                                                        D.climbSpeedMps}
                              end
            TargetTakeOff = if (LastRollTime + RequiredSpacing) > EarliestStart then
                               LastRollTime + RequiredSpacing
                            else
                               EarliestStart
                            end
            TargetStartup = TargetTakeOff - D.exot
            UpdatedDep = departure(callsign: D.callsign
                                   recatCategory: D.recatCategory
                                   tobt: D.tobt
                                   exot: D.exot
                                   tsat: TargetStartup
                                   ttot: TargetTakeOff
                                   initialHeadingDeg: D.initialHeadingDeg
                                   climbSpeedMps: D.climbSpeedMps)
         in
            UpdatedDep | {ScheduleQueue Rest TargetTakeOff D.recatCategory D.initialHeadingDeg D.climbSpeedMps}
         end
      end
   in
      {ScheduleQueue Sorted 0.0 cat_d 0.0 120.0}
   end

   % --------------------------------------------------------------------------
   % Total Delay: Sum of (TTOT - EarliestAvailability) across all departures
   % --------------------------------------------------------------------------
   fun {EvaluateTotalDepartureDelay SequencedDepartures}
      case SequencedDepartures
      of nil then 0.0
      [] D | Rest then
         Earliest = D.tobt + D.exot
         Delay = if D.ttot > Earliest then D.ttot - Earliest else 0.0 end
      in
         Delay + {EvaluateTotalDepartureDelay Rest}
      end
   end

end
