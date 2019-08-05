% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.SpaceSearch
% Description: First-class Oz computation space search abstractions, choice point
%              commitments, and branch-and-bound pruning for combinatorial scheduling.
% =============================================================================

functor
import
   Space
   System
export
   SolveOne: SolveOne
   SolveAll: SolveAll
   OptimizeBest: OptimizeBest
define

   % --------------------------------------------------------------------------
   % SolveOne: Returns first valid solution space or none
   % --------------------------------------------------------------------------
   fun {SolveOne ProblemProc}
      local Sp in
         Sp = {Space.new ProblemProc}
         fun {Search S}
            case {Space.ask S}
            of failed then none
            [] succeeded then opt({Space.merge S})
            [] alternatives(N) then
               % Speculatively explore branch 1
               Choice1 = {Space.clone S}
               {Space.commit Choice1 1}
               case {Search Choice1}
               of opt(Sol) then opt(Sol)
               [] none then
                  if N >= 2 then
                     Choice2 = {Space.clone S}
                     {Space.commit Choice2 2}
                  in
                     {Search Choice2}
                  else
                     none
                  end
               end
            end
         end
      in
         {Search Sp}
      end
   end

   % --------------------------------------------------------------------------
   % SolveAll: Returns all feasible solutions in a list
   % --------------------------------------------------------------------------
   fun {SolveAll ProblemProc}
      local Sp in
         Sp = {Space.new ProblemProc}
         fun {Search S}
            case {Space.ask S}
            of failed then nil
            [] succeeded then {Space.merge S} | nil
            [] alternatives(N) then
               Choice1 = {Space.clone S}
               {Space.commit Choice1 1}
               Sols1 = {Search Choice1}
               Sols2 = if N >= 2 then
                          Choice2 = {Space.clone S}
                          {Space.commit Choice2 2}
                       in
                          {Search Choice2}
                       else
                          nil
                       end
            in
               {Append Sols1 Sols2}
            end
         end
      in
         {Search Sp}
      end
   end

   % --------------------------------------------------------------------------
   % OptimizeBest: Branch-and-bound optimization
   % Explores state space, updating best bound Cost whenever a solution is discovered
   % --------------------------------------------------------------------------
   fun {OptimizeBest ProblemProc CostKey}
      local RootSp in
         RootSp = {Space.new ProblemProc}
         fun {BranchAndBound S BestSol BestCost}
            case {Space.ask S}
            of failed then
               BestSol
            [] succeeded then
               Sol = {Space.merge S}
               Cost = Sol.CostKey
            in
               if Cost < BestCost then
                  opt(Sol)
               else
                  BestSol
               end
            [] alternatives(N) then
               Choice1 = {Space.clone S}
               {Space.commit Choice1 1}
               NewBest = {BranchAndBound Choice1 BestSol BestCost}
               CurBestCost = case NewBest
                             of opt(B) then B.CostKey
                             [] none then BestCost
                             end
            in
               if N >= 2 then
                  Choice2 = {Space.clone S}
                  {Space.commit Choice2 2}
               in
                  {BranchAndBound Choice2 NewBest CurBestCost}
               else
                  NewBest
               end
            end
         end
      in
         {BranchAndBound RootSp none 1e12}
      end
   end

end
