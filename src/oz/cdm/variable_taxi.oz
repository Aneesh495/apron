% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.VariableTaxi
% Description: Variable Estimated Taxi-Out Time (EXOT) predictor taking into
%              account topological distance, surface traffic density, and de-icing.
% =============================================================================

functor
export
   PredictEXOT: PredictEXOT
   ComputeUnimpededTaxiTime: ComputeUnimpededTaxiTime
define

   % --------------------------------------------------------------------------
   % ComputeUnimpededTaxiTime: Baseline taxi time with zero surface congestion
   % --------------------------------------------------------------------------
   fun {ComputeUnimpededTaxiTime TopologicalDistanceMeters NominalSpeedMps}
      TopologicalDistanceMeters / NominalSpeedMps
   end

   % --------------------------------------------------------------------------
   % PredictEXOT: Variable Estimated Taxi-Out Time (seconds)
   % EXOT = UnimpededTime * (1 + CongestionFactor * ActiveTrafficCount)
   %        + ExpectedCrossingDelays + DeicingTransitBuffer
   % --------------------------------------------------------------------------
   fun {PredictEXOT DistanceMeters ActiveTaxiingAircraft RunwayCrossings RequiresDeicing}
      Unimpeded = {ComputeUnimpededTaxiTime DistanceMeters 10.0} % 10 m/s (~20 kt)
      TrafficCountFloat = {IntToFloat ActiveTaxiingAircraft}
      CongestionPenalty = 1.0 + (0.03 * TrafficCountFloat) % 3% extra delay per active aircraft
      CrossingDelay = {IntToFloat RunwayCrossings} * 90.0   % 90s per active runway crossing
      DeicingBuffer = if RequiresDeicing then 480.0 else 0.0 end
      TotalSec = (Unimpeded * CongestionPenalty) + CrossingDelay + DeicingBuffer
   in
      TotalSec
   end

end
