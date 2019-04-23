% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.Prelude
% Description: Fundamental higher-order combinators, identity mappings, and
%              functional utility procedures for the Oz execution runtime.
% =============================================================================

functor
import
   System
export
   Identity: Identity
   Const: Const
   Compose: Compose
   Curry: Curry
   Uncurry: Uncurry
   Flip: Flip
   Until: Until
   Iterate: Iterate
   Assert: Assert
   Apply: Apply
   Branch: Branch
   When: When
   Unless: Unless
   TryCatchDefault: TryCatchDefault
define

   % --------------------------------------------------------------------------
   % Identity Function
   % Returns its input value unchanged: Identity(X) = X
   % --------------------------------------------------------------------------
   fun {Identity X}
      X
   end

   % --------------------------------------------------------------------------
   % Constant Generator
   % Returns a zero-argument function that always evaluates to X
   % --------------------------------------------------------------------------
   fun {Const X}
      fun {$} X end
   end

   % --------------------------------------------------------------------------
   % Function Composition: (F o G)(X) = F(G(X))
   % --------------------------------------------------------------------------
   fun {Compose F G}
      fun {$ X}
         {F {G X}}
      end
   end

   % --------------------------------------------------------------------------
   % Currying: Converts a binary procedure into a unary higher-order procedure
   % --------------------------------------------------------------------------
   fun {Curry BinaryProc}
      fun {$ X}
         fun {$ Y}
            {BinaryProc X Y}
         end
      end
   end

   % --------------------------------------------------------------------------
   % Uncurrying: Converts a curried procedure into a binary procedure
   % --------------------------------------------------------------------------
   fun {Uncurry CurriedProc}
      fun {$ X Y}
         {{CurriedProc X} Y}
      end
   end

   % --------------------------------------------------------------------------
   % Argument Flop: Swaps order of arguments for a binary function
   % --------------------------------------------------------------------------
   fun {Flip BinaryFn}
      fun {$ X Y}
         {BinaryFn Y X}
      end
   end

   % --------------------------------------------------------------------------
   % Fixed Point Iterator
   % Repeats application of F starting at X until predicate Pred is satisfied
   % --------------------------------------------------------------------------
   fun {Until Pred F X}
      if {Pred X} then
         X
      else
         {Until Pred F {F X}}
      end
   end

   % --------------------------------------------------------------------------
   % Infinite Stream Generator by Repeated Iteration
   % Generates [X, F(X), F(F(X)), ...] as a lazy concurrent stream
   % --------------------------------------------------------------------------
   fun {Iterate F X}
      X | {Iterate F {F X}}
   end

   % --------------------------------------------------------------------------
   % Assertion Helper
   % Verifies Boolean condition; prints diagnostic message on assertion failure
   % --------------------------------------------------------------------------
   proc {Assert Condition Message}
      if Condition == false then
         {System.show assertion_failed(message: Message)}
      else
         skip
      end
   end

   % --------------------------------------------------------------------------
   % Dynamic Application
   % Evaluates procedure Fn over arguments Arg1, Arg2
   % --------------------------------------------------------------------------
   fun {Apply Fn Arg1 Arg2}
      {Fn Arg1 Arg2}
   end

   % --------------------------------------------------------------------------
   % Conditional Branch Evaluator
   % Evaluates ThenFn if Cond is true, otherwise ElseFn
   % --------------------------------------------------------------------------
   fun {Branch Cond ThenFn ElseFn Value}
      if Cond then
         {ThenFn Value}
      else
         {ElseFn Value}
      end
   end

   % --------------------------------------------------------------------------
   % Guarded Execution (When)
   % Executes Action only if Condition holds
   % --------------------------------------------------------------------------
   proc {When Condition Action}
      if Condition then
         {Action}
      else
         skip
      end
   end

   % --------------------------------------------------------------------------
   % Inverted Guarded Execution (Unless)
   % Executes Action only if Condition is false
   % --------------------------------------------------------------------------
   proc {Unless Condition Action}
      if Condition == false then
         {Action}
      else
         skip
      end
   end

   % --------------------------------------------------------------------------
   % Fault Tolerant Evaluation
   % Executes Action and falls back to DefaultVal on error
   % --------------------------------------------------------------------------
   fun {TryCatchDefault Action DefaultVal}
      try
         {Action}
      catch _ then
         DefaultVal
      end
   end

end
