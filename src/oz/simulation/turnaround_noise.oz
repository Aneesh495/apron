% =============================================================================
% Apron Stochastic Turnaround Duration & Operational Noise
% Module: TurnaroundNoise
%
% Implements stochastic models for ground turnaround variability, passenger
% boarding variance, baggage loading bottlenecks, fueling flow fluctuations,
% and cascading network delay propagation.
% =============================================================================

functor
export
    SampleTurnaroundDelta: SampleTurnaroundDelta
    SampleBoardingDuration: SampleBoardingDuration
    ComputeCascadingDelay: ComputeCascadingDelay
define

    % Computes delta variation around nominal scheduled turnaround time (seconds)
    fun {SampleTurnaroundDelta AcCategory PaxCount Rand1 Rand2}
        BaseVariation = (Rand1 - 0.4) * 600.0 % -240 to +360 seconds
        PaxDelayFactor = if PaxCount > 250 andthen Rand2 > 0.75 then
                             (Rand2 - 0.75) * 1200.0 % passenger boarding bottleneck
                         else
                             0.0
                         end
    in
        BaseVariation + PaxDelayFactor
    end

    % Nominal boarding rate ~ 20 passengers per minute for single-aisle,
    % 35 passengers per minute for dual-aisle with dual jet bridges
    fun {SampleBoardingDuration PaxCount IsWidebody JetBridgeCount Rand}
        RatePerMin = if IsWidebody andthen JetBridgeCount >= 2 then
                         35.0
                     else
                         20.0
                     end
        NominalMins = {IntToFloat PaxCount} / RatePerMin
        StochasticMultiplier = 0.9 + (Rand * 0.3) % 0.9x to 1.2x
    in
        NominalMins * 60.0 * StochasticMultiplier
    end

    % Computes turnaround ripple delay to subsequent outbound leg
    fun {ComputeCascadingDelay InboundActualArrival OutboundSchedDeparture MinTurnaroundSec}
        AvailableTurnaround = OutboundSchedDeparture - InboundActualArrival
    in
        if AvailableTurnaround < MinTurnaroundSec then
            MinTurnaroundSec - AvailableTurnaround
        else
            0
        end
    end

end
