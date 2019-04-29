% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.MathExt
% Description: Numeric routines, trigonometry, statistics, stochastic random
%              variate generation (Gaussian, Poisson, Lognormal) for turnaround simulation.
% =============================================================================

functor
import
   Math
   System
export
   Clamp: Clamp
   Lerp: Lerp
   NormalizeAngleDeg: NormalizeAngleDeg
   AngleDiffDeg: AngleDiffDeg
   DegToRad: DegToRad
   RadToDeg: RadToDeg
   Mean: Mean
   Variance: Variance
   StdDev: StdDev
   Median: Median
   Percentile: Percentile
   RandomNext: RandomNext
   RandomUniform: RandomUniform
   RandomGaussian: RandomGaussian
   RandomExponential: RandomExponential
   RandomLognormal: RandomLognormal
define

   Pi = 3.14159265358979323846

   fun {DegToRad Deg}
      Deg * (Pi / 180.0)
   end

   fun {RadToDeg Rad}
      Rad * (180.0 / Pi)
   end

   % --------------------------------------------------------------------------
   % Clamp: Constrains value X to interval [MinVal, MaxVal]
   % --------------------------------------------------------------------------
   fun {Clamp X MinVal MaxVal}
      if X < MinVal then
         MinVal
      elseif X > MaxVal then
         MaxVal
      else
         X
      end
   end

   % --------------------------------------------------------------------------
   % Linear Interpolation: Lerp(A, B, T) = A + T * (B - A)
   % --------------------------------------------------------------------------
   fun {Lerp A B T}
      A + T * (B - A)
   end

   % --------------------------------------------------------------------------
   % NormalizeAngleDeg: Normalizes bearing to [0, 360)
   % --------------------------------------------------------------------------
   fun {NormalizeAngleDeg Angle}
      Rem = Angle - {IntToFloat ({FloatToInt Angle} div 360) * 360}
   in
      if Rem < 0.0 then Rem + 360.0 else Rem end
   end

   % --------------------------------------------------------------------------
   % AngleDiffDeg: Smallest signed angular difference from Angle1 to Angle2 [-180, 180]
   % --------------------------------------------------------------------------
   fun {AngleDiffDeg Angle1 Angle2}
      Diff = {NormalizeAngleDeg Angle2 - Angle1}
   in
      if Diff > 180.0 then Diff - 360.0 else Diff end
   end

   % --------------------------------------------------------------------------
   % Statistical Reductions
   % --------------------------------------------------------------------------
   fun {Sum Xs}
      case Xs
      of nil then 0.0
      [] H | T then
         Val = if {IsInt H} then {IntToFloat H} else H end
      in
         Val + {Sum T}
      end
   end

   fun {Mean Xs}
      Len = {Length Xs}
   in
      if Len == 0 then
         0.0
      else
         {Sum Xs} / {IntToFloat Len}
      end
   end

   fun {Variance Xs}
      Len = {Length Xs}
   in
      if Len =< 1 then
         0.0
      else
         M = {Mean Xs}
         fun {SqDiffSum List}
            case List
            of nil then 0.0
            [] H | T then
               Val = if {IsInt H} then {IntToFloat H} else H end
               Diff = Val - M
            in
               (Diff * Diff) + {SqDiffSum T}
            end
         end
      in
         {SqDiffSum Xs} / {IntToFloat (Len - 1)}
      end
   end

   fun {StdDev Xs}
      {Math.sqrt {Variance Xs}}
   end

   % Insertion sort for median computation
   fun {SortFloats Xs}
      fun {Insert X List}
         case List
         of nil then X | nil
         [] H | T then
            if X =< H then X | H | T else H | {Insert X T} end
         end
      end
      fun {SortAux List Acc}
         case List
         of nil then Acc
         [] H | T then {SortAux T {Insert H Acc}}
         end
      end
   in
      {SortAux Xs nil}
   end

   fun {Median Xs}
      Sorted = {SortFloats Xs}
      Len = {Length Sorted}
   in
      if Len == 0 then
         0.0
      elseif (Len mod 2) == 1 then
         {Nth Sorted (Len div 2) + 1}
      else
         Mid1 = {Nth Sorted (Len div 2)}
         Mid2 = {Nth Sorted (Len div 2) + 1}
      in
         (Mid1 + Mid2) / 2.0
      end
   end

   fun {Percentile Xs P}
      Sorted = {SortFloats Xs}
      Len = {Length Sorted}
   in
      if Len == 0 then
         0.0
      else
         Rank = {FloatToInt ((P / 100.0) * {IntToFloat Len})}
         SafeRank = {Clamp Rank 1 Len}
      in
         {Nth Sorted SafeRank}
      end
   end

   % --------------------------------------------------------------------------
   % Pseudo-Random Number Generation: 64-bit LCG
   % Returns pair(NextRandomFloat in [0, 1), NextSeed)
   % --------------------------------------------------------------------------
   A_LCG = 6364136223846793005
   C_LCG = 1442695040888963407

   fun {RandomNext Seed}
      NextSeed = (Seed * 1103515245 + 12345) mod 2147483647
      FloatVal = {IntToFloat (NextSeed mod 1000000)} / 1000000.0
   in
      pair(FloatVal NextSeed)
   end

   fun {RandomUniform Seed MinVal MaxVal}
      case {RandomNext Seed}
      of pair(U NextSeed) then
         Val = MinVal + U * (MaxVal - MinVal)
      in
         pair(Val NextSeed)
      end
   end

   % --------------------------------------------------------------------------
   % Box-Muller Gaussian Variate Generation
   % --------------------------------------------------------------------------
   fun {RandomGaussian Seed MeanVal StdVal}
      case {RandomNext Seed}
      of pair(U1 S1) then
         SafeU1 = if U1 < 1e-7 then 1e-7 else U1 end
         case {RandomNext S1}
         of pair(U2 S2) then
            % Standard normal Z0 = sqrt(-2 ln U1) * cos(2 pi U2)
            R = {Math.sqrt ~2.0 * {Log SafeU1}}
            Theta = 2.0 * Pi * U2
            Z0 = R * {Math.cos Theta}
            Result = MeanVal + Z0 * StdVal
         in
            pair(Result S2)
         end
      end
   end

   % Approximation of natural logarithm ln(X)
   fun {Log X}
      % Taylor expansion around 1 for log
      if X =< 0.0 then
         ~10.0
      else
         Y = (X - 1.0) / (X + 1.0)
         Y2 = Y * Y
      in
         2.0 * Y * (1.0 + Y2 / 3.0 + (Y2 * Y2) / 5.0)
      end
   end

   % --------------------------------------------------------------------------
   % Stochastic Poisson / Exponential Inter-Arrival Generator
   % Generates time between events with rate parameter Lambda
   % --------------------------------------------------------------------------
   fun {RandomExponential Seed Lambda}
      case {RandomNext Seed}
      of pair(U S1) then
         SafeU = if U < 1e-7 then 1e-7 else U end
         InterArrival = ~1.0 * {Log SafeU} / Lambda
      in
         pair(InterArrival S1)
      end
   end

   % --------------------------------------------------------------------------
   % Lognormal Distribution for Turnaround Delays
   % X = exp(Mu + Sigma * Z)
   % --------------------------------------------------------------------------
   fun {RandomLognormal Seed Mu Sigma}
      case {RandomGaussian Seed Mu Sigma}
      of pair(G S1) then
         % exp approximation
         ExpVal = {Exp G}
      in
         pair(ExpVal S1)
      end
   end

   fun {Exp X}
      % Taylor approximation of exp(X)
      1.0 + X + (X * X) / 2.0 + (X * X * X) / 6.0
   end

end
