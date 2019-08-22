% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.ReroutingEngine
% Description: Reactive dynamic taxiway rerouting engine triggered by surface jams,
%              foreign object debris (FOD), disabled aircraft, or gate blockages.
% =============================================================================

functor
import
   Pathfinder at 'pathfinder.oz'
   SpaceTimeGraph at 'spacetime_graph.oz'
   Graph at '../aerodrome/graph.oz'
export
   HandleTaxiwayClosure: HandleTaxiwayClosure
define

   % --------------------------------------------------------------------------
   % HandleTaxiwayClosure: Updates airfield graph to disable blocked edge,
   % purges conflicting reservations, and computes bypass trajectory.
   % --------------------------------------------------------------------------
   fun {HandleTaxiwayClosure AirfieldGraph ResTable BlockedEdgeId AffectedAircraftList CurrentTime BufferSec}
      % 1. Mark edge inactive in graph
      fun {DeactivateEdge Edges}
         case Edges
         of nil then nil
         [] E | Rest then
            if E.id == BlockedEdgeId then
               edge(id: E.id
                    from: E.from
                    to: E.to
                    length: E.length
                    maxSpeed: E.maxSpeed
                    width: E.width
                    radius: E.radius
                    kind: E.kind
                    active: false) | Rest
            else
               E | {DeactivateEdge Rest}
            end
         end
      end

      UpdatedGraph = graph(nodes: AirfieldGraph.nodes
                           edges: {DeactivateEdge AirfieldGraph.edges})

      % 2. Re-route affected aircraft
      fun {RerouteBatch AircraftList CurTable ReroutedAcc}
         case AircraftList
         of nil then
            pair(ReroutedAcc CurTable)
         [] Ac | Rest then
            % Release old reservations for this flight
            CleanedTable = {SpaceTimeGraph.ReleaseFlightReservations CurTable Ac.flightId}

            % Plan new route from current position to destination
            case {Pathfinder.FindConflictFreeRoute UpdatedGraph
                                                   CleanedTable
                                                   Ac.flightId
                                                   Ac.currentNodeId
                                                   Ac.destinationNodeId
                                                   CurrentTime
                                                   BufferSec}
            of pair(opt(NewTraj) UpdTable) then
               ReroutedRecord = rerouted(flightId: Ac.flightId
                                         status: success
                                         newTrajectory: NewTraj)
            in
               {RerouteBatch Rest UpdTable ReroutedRecord | ReroutedAcc}
            [] pair(none SameTable) then
               ReroutedRecord = rerouted(flightId: Ac.flightId
                                         status: failed_no_path
                                         newTrajectory: none)
            in
               {RerouteBatch Rest SameTable ReroutedRecord | ReroutedAcc}
            end
         end
      end
   in
      {RerouteBatch AffectedAircraftList ResTable nil}
   end

end
