% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Graph
% Description: Directed planar multigraph representing the airfield surface movement
%              area, taxiway connectivity, and topological spatial queries.
% =============================================================================

functor
import
   System
export
   New: New
   AddNode: AddNode
   AddEdge: AddEdge
   GetNode: GetNode
   GetOutgoingEdges: GetOutgoingEdges
   GetIncomingEdges: GetIncomingEdges
   AllNodes: AllNodes
   AllEdges: AllEdges
   Dijkstra: Dijkstra
define

   % --------------------------------------------------------------------------
   % Airfield Graph Structure:
   % graph(nodes: NodeDict edges: EdgeList)
   % --------------------------------------------------------------------------

   fun {New}
      graph(nodes: nil edges: nil)
   end

   % --------------------------------------------------------------------------
   % Node Definition:
   % node(id: Id name: Name kind: Kind x: X y: Y z: Z code: MaxCode)
   % --------------------------------------------------------------------------
   fun {AddNode G NodeRecord}
      case G
      of graph(nodes: Ns edges: Es) then
         graph(nodes: NodeRecord | Ns edges: Es)
      end
   end

   % --------------------------------------------------------------------------
   % Edge Definition:
   % edge(id: Id from: FromNode to: ToNode length: Len maxSpeed: Spd
   %      width: W radius: R kind: Kind active: IsActive)
   % --------------------------------------------------------------------------
   fun {AddEdge G EdgeRecord}
      case G
      of graph(nodes: Ns edges: Es) then
         graph(nodes: Ns edges: EdgeRecord | Es)
      end
   end

   % --------------------------------------------------------------------------
   % Node Lookup
   % --------------------------------------------------------------------------
   fun {GetNode G NodeId}
      case G.nodes
      of nil then none
      [] N | Rest then
         if N.id == NodeId then
            opt(N)
         else
            {GetNode graph(nodes: Rest edges: G.edges) NodeId}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Outgoing and Incoming Edge Queries
   % --------------------------------------------------------------------------
   fun {GetOutgoingEdges G NodeId}
      fun {Filter List}
         case List
         of nil then nil
         [] E | Rest then
            if E.from == NodeId andthen E.active then
               E | {Filter Rest}
            else
               {Filter Rest}
            end
         end
      end
   in
      {Filter G.edges}
   end

   fun {GetIncomingEdges G NodeId}
      fun {Filter List}
         case List
         of nil then nil
         [] E | Rest then
            if E.to == NodeId andthen E.active then
               E | {Filter Rest}
            else
               {Filter Rest}
            end
         end
      end
   in
      {Filter G.edges}
   end

   fun {AllNodes G}
      G.nodes
   end

   fun {AllEdges G}
      G.edges
   end

   % --------------------------------------------------------------------------
   % Static Dijkstra Shortest Path Search
   % Finds minimum distance path from StartNodeId to GoalNodeId
   % Returns pair(opt(PathEdgeList), TotalDistance)
   % --------------------------------------------------------------------------
   fun {Dijkstra G StartNodeId GoalNodeId}
      fun {ExtractMin Q BestNode BestDist BestRest}
         case Q
         of nil then pair(BestNode BestDist BestRest)
         [] pair(N D) | Rest then
            if D < BestDist then
               NewRest = if BestNode == none then Rest else pair(BestNode BestDist) | Rest end
            in
               {ExtractMin Rest N D NewRest}
            else
               {ExtractMin Rest BestNode BestDist pair(N D) | BestRest}
            end
         end
      end

      fun {GetDist DistList NodeId}
         case DistList
         of nil then 1e9
         [] pair(N D) | Rest then
            if N == NodeId then D else {GetDist Rest NodeId} end
         end
      end

      fun {SetDist DistList NodeId NewD}
         case DistList
         of nil then pair(NodeId NewD) | nil
         [] pair(N D) | Rest then
            if N == NodeId then
               pair(NodeId NewD) | Rest
            else
               pair(N D) | {SetDist Rest NodeId NewD}
            end
         end
      end

      fun {Search OpenList Distances Visited Parents}
         case OpenList
         of nil then
            pair(none 1e9)
         else
            case {ExtractMin OpenList none 1e9 nil}
            of pair(CurrNode CurrDist RestOpen) then
               if CurrNode == GoalNodeId then
                  pair(opt(CurrDist) CurrDist)
               else
                  Neighbors = {GetOutgoingEdges G CurrNode}
                  fun {RelaxEdges Edges CurDistances CurOpen CurParents}
                     case Edges
                     of nil then
                        pair(CurDistances CurOpen CurParents)
                     [] E | Er then
                        Neighbor = E.to
                        NewDist = CurrDist + E.length
                        OldDist = {GetDist CurDistances Neighbor}
                     in
                        if NewDist < OldDist then
                           UpdDist = {SetDist CurDistances Neighbor NewDist}
                           UpdOpen = pair(Neighbor NewDist) | CurOpen
                           UpdParents = pair(Neighbor E) | CurParents
                        in
                           {RelaxEdges Er UpdDist UpdOpen UpdParents}
                        else
                           {RelaxEdges Er CurDistances CurOpen CurParents}
                        end
                     end
                  end
                  case {RelaxEdges Neighbors Distances RestOpen Parents}
                  of pair(NextDist NextOpen NextParents) then
                     {Search NextOpen NextDist CurrNode | Visited NextParents}
                  end
               end
            end
         end
      end

      InitialDist = pair(StartNodeId 0.0) | nil
      InitialOpen = pair(StartNodeId 0.0) | nil
   in
      {Search InitialOpen InitialDist nil nil}
   end

end
