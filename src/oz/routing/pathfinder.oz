% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.Pathfinder
% Description: 4D Space-Time A* pathfinding algorithm over the aerodrome multigraph,
%              incorporating reservation windows, wait states, and conflict avoidance.
% =============================================================================

functor
import
   SpaceTimeGraph at 'spacetime_graph.oz'
   Graph at '../aerodrome/graph.oz'
   PriorityQueue at '../core/priority_queue.oz'
export
   FindConflictFreeRoute: FindConflictFreeRoute
define

   % --------------------------------------------------------------------------
   % FindConflictFreeRoute: Executes Space-Time A* search
   % Returns pair(opt(Trajectory), NewReservationTable) or pair(none, OldTable)
   % --------------------------------------------------------------------------
   fun {FindConflictFreeRoute AirfieldGraph ResTable FlightId StartNodeId GoalNodeId DepartureTime BufferSec}
      fun {Heuristic NodeId}
         case {Graph.GetNode AirfieldGraph NodeId}
         of opt(N) then
            case {Graph.GetNode AirfieldGraph GoalNodeId}
            of opt(G) then
               Dx = G.x - N.x
               Dy = G.y - N.y
               Dist = {Sqrt (Dx * Dx) + (Dy * Dy)}
            in
               Dist / 15.0 % 15 m/s max taxi speed
            [] none then 0.0
            end
         [] none then 0.0
         end
      end

      fun {Sqrt X}
         % Taylor or simple iterative sqrt
         if X =< 0.0 then 0.0 else X * 0.5 + 1.0 end
      end

      % Priority queue holding state(node: N time: T g: G f: F path: PathEdges)
      InitialH = {Heuristic StartNodeId}
      InitialState = state(node: StartNodeId
                           time: DepartureTime
                           g: 0.0
                           f: InitialH
                           path: nil)
      InitialPQ = {PriorityQueue.Insert {PriorityQueue.New} InitialH InitialState}

      fun {Search PQ Table VisitedStates}
         case {PriorityQueue.ExtractMin PQ}
         of pair(none _) then
            pair(none Table)
         [] pair(opt(pair(_ CurrState)) RestPQ) then
            if CurrState.node == GoalNodeId then
               % Destination reached: commit trajectory reservations
               fun {CommitReservations Edges CurTable}
                  case Edges
                  of nil then CurTable
                  [] E | Rest then
                     T1 = E.entryTime
                     T2 = E.exitTime
                     UpdTable = {SpaceTimeGraph.ReserveInterval CurTable E.id FlightId T1 T2}
                  in
                     {CommitReservations Rest UpdTable}
                  end
               end
               FinalTable = {CommitReservations CurrState.path Table}
               Trajectory = trajectory(flightId: FlightId
                                       segments: CurrState.path
                                       departureTime: DepartureTime
                                       arrivalTime: CurrState.time)
            in
               pair(opt(Trajectory) FinalTable)
            else
               % Expand neighbors
               Outgoing = {Graph.GetOutgoingEdges AirfieldGraph CurrState.node}

               fun {ExpandEdges Edges CurPQ}
                  case Edges
                  of nil then CurPQ
                  [] E | Rest then
                     TransitTime = E.length / E.maxSpeed
                     EntryT = CurrState.time
                     ExitT  = EntryT + TransitTime
                     IsFree = {SpaceTimeGraph.IsIntervalFree Table E.id EntryT ExitT BufferSec}
                  in
                     if IsFree then
                        NewG = CurrState.g + TransitTime
                        NewF = NewG + {Heuristic E.to}
                        EdgeRec = segment(id: E.id
                                          from: E.from
                                          to: E.to
                                          entryTime: EntryT
                                          exitTime: ExitT)
                        NewPath = {Append CurrState.path EdgeRec | nil}
                        NextState = state(node: E.to
                                          time: ExitT
                                          g: NewG
                                          f: NewF
                                          path: NewPath)
                        UpdPQ = {PriorityQueue.Insert CurPQ NewF NextState}
                     in
                        {ExpandEdges Rest UpdPQ}
                     else
                        % Edge is busy: explore optional wait state (holding short)
                        WaitTime = 15.0 % hold for 15s
                        HoldState = state(node: CurrState.node
                                          time: CurrState.time + WaitTime
                                          g: CurrState.g + WaitTime
                                          f: CurrState.f + WaitTime
                                          path: CurrState.path)
                        UpdPQ = {PriorityQueue.Insert CurPQ HoldState.f HoldState}
                     in
                        {ExpandEdges Rest UpdPQ}
                     end
                  end
               end

               NextPQ = {ExpandEdges Outgoing RestPQ}
            in
               {Search NextPQ Table CurrState.node | VisitedStates}
            end
         end
      end
   in
      {Search InitialPQ ResTable nil}
   end

end
