% =============================================================================
% Apron Runway Occupancy Time (ROT) Stochastic Distribution
% Module: ROTDistribution
%
% Models empirical Runway Occupancy Time distributions for arriving and
% departing aircraft across ICAO weight classes (Super, Heavy, Medium, Light).
% Accounts for runway surface conditions (dry, wet) and RET exit availability.
% =============================================================================

functor
export
    SampleArrivalROT: SampleArrivalROT
    SampleDepartureROT: SampleDepartureROT
    GetNominalROT: GetNominalROT
define

    % Arrival ROT values in seconds:
    % Heavy: mean 55s, Medium: mean 48s, Light: mean 40s
    fun {GetNominalROT WeightCat Operation SurfaceCondition}
        BaseROT = case Operation
                  of arrival then
                      case WeightCat
                      of super then 60.0
                      [] heavy then 54.0
                      [] medium then 46.0
                      [] light then 38.0
                      else 48.0
                      end
                  [] departure then
                      case WeightCat
                      of super then 58.0
                      [] heavy then 50.0
                      [] medium then 42.0
                      [] light then 32.0
                      else 44.0
                      end
                  else 45.0
                  end
        % Surface penalty
        Penalty = case SurfaceCondition
                  of wet then 6.0
                  [] contaminated then 14.0
                  else 0.0
                  end
    in
        BaseROT + Penalty
    end

    fun {SampleArrivalROT WeightCat SurfaceCondition UniformRand}
        Nominal = {GetNominalROT WeightCat arrival SurfaceCondition}
        % Perturbation between -5.0 and +15.0 seconds
        Variance = (UniformRand - 0.3) * 15.0
    in
        Nominal + Variance
    end

    fun {SampleDepartureROT WeightCat SurfaceCondition UniformRand}
        Nominal = {GetNominalROT WeightCat departure SurfaceCondition}
        % Perturbation between -3.0 and +10.0 seconds
        Variance = (UniformRand - 0.2) * 12.0
    in
        Nominal + Variance
    end

end
