% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.Turnaround
% Description: Critical path modeling of ground turnaround sub-processes (deboarding,
%              cleaning, catering, fueling, boarding) and passenger boarding clocks.
% =============================================================================

functor
export
   NewTurnaroundPlan: NewTurnaroundPlan
   ComputeCriticalPathDuration: ComputeCriticalPathDuration
   SimulateBoardingProgress: SimulateBoardingProgress
   IsTurnaroundFeasible: IsTurnaroundFeasible
define

   % --------------------------------------------------------------------------
   % Turnaround Plan Structure:
   % plan(flightId: String
   %      deboardSec: Float
   %      cleanSec: Float
   %      caterSec: Float
   %      fuelSec: Float
   %      cargoSec: Float
   %      boardSec: Float
   %      doorsClosedBufferSec: Float)
   % --------------------------------------------------------------------------

   fun {NewTurnaroundPlan FlightId AcCode PassengerCount CargoTonnes}
      % Compute duration estimates based on aircraft scale
      Deboard = case AcCode
                of code_f then 1800.0  % 30 min (A380)
                [] code_e then 1200.0  % 20 min (B777/A350)
                [] code_d then 900.0   % 15 min
                [] code_c then 600.0   % 10 min (A320/B737)
                else 480.0
                end
      Clean = case AcCode
              of code_f then 2400.0
              [] code_e then 1500.0
              [] code_d then 1000.0
              [] code_c then 720.0
              else 480.0
              end
      Cater = Clean * 0.9
      Fuel  = 600.0 + (CargoTonnes * 60.0)
      Cargo = 600.0 + (CargoTonnes * 80.0)
      Board = {IntToFloat PassengerCount} * 2.5 % 2.5 seconds per passenger
   in
      plan(flightId: FlightId
           deboardSec: Deboard
           cleanSec: Clean
           caterSec: Cater
           fuelSec: Fuel
           cargoSec: Cargo
           boardSec: Board
           doorsClosedBufferSec: 300.0) % 5 minute door closing buffer
   end

   % --------------------------------------------------------------------------
   % Critical Path Analysis:
   % Passenger path: Deboard -> Clean -> Board -> DoorsClosed
   % Parallel paths: Fueling, Cargo loading
   % --------------------------------------------------------------------------
   fun {ComputeCriticalPathDuration Plan}
      PassengerPath = Plan.deboardSec + Plan.cleanSec + Plan.boardSec + Plan.doorsClosedBufferSec
      CateringPath  = Plan.deboardSec + Plan.caterSec + Plan.boardSec + Plan.doorsClosedBufferSec
      FuelingPath   = Plan.fuelSec + Plan.doorsClosedBufferSec
      CargoPath     = Plan.cargoSec + Plan.doorsClosedBufferSec

      fun {Max A B} if A > B then A else B end end
      Path1 = {Max PassengerPath CateringPath}
      Path2 = {Max FuelingPath CargoPath}
   in
      {Max Path1 Path2}
   end

   % --------------------------------------------------------------------------
   % Simulate Boarding Rate: Returns boarded passenger count at ElapsedSeconds
   % --------------------------------------------------------------------------
   fun {SimulateBoardingProgress TotalPax BoardingDurationSec ElapsedSec}
      if ElapsedSec =< 0.0 then
         0
      elseif ElapsedSec >= BoardingDurationSec then
         TotalPax
      else
         Fraction = ElapsedSec / BoardingDurationSec
         Boarded = {FloatToInt (Fraction * {IntToFloat TotalPax})}
      in
         Boarded
      end
   end

   fun {IsTurnaroundFeasible Plan AvailableTurnaroundSec}
      AvailableTurnaroundSec >= {ComputeCriticalPathDuration Plan}
   end

end
