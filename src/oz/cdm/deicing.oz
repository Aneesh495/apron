% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.Deicing
% Description: SAE Type I/II/IV de-icing fluid Holdover Time (HOT) calculation,
%              temperature bands, weather precipitation categories, and queue slots.
% =============================================================================

functor
export
   FLUID_TYPE_I: FLUID_TYPE_I
   FLUID_TYPE_II: FLUID_TYPE_II
   FLUID_TYPE_IV: FLUID_TYPE_IV
   GetHoldoverTimeSeconds: GetHoldoverTimeSeconds
   IsHoldoverTimeValid: IsHoldoverTimeValid
define

   FLUID_TYPE_I  = fluid_type_i
   FLUID_TYPE_II = fluid_type_ii
   FLUID_TYPE_IV = fluid_type_iv

   % --------------------------------------------------------------------------
   % Holdover Time (HOT) in seconds based on SAE Tables
   % --------------------------------------------------------------------------
   fun {GetHoldoverTimeSeconds FluidType TempC WeatherCondition}
      case FluidType
      of fluid_type_i then
         % Type I has brief protection window (de-icing only)
         case WeatherCondition
         of frost then 1200.0          % 20 min
         [] freezing_fog then 660.0    % 11 min
         [] light_snow then 720.0      % 12 min
         [] moderate_snow then 360.0   % 6 min
         [] freezing_rain then 180.0   % 3 min
         else 600.0
         end

      [] fluid_type_ii then
         % Type II thickened anti-icing
         if TempC >= 0.0 then
            case WeatherCondition
            of frost then 5400.0        % 90 min
            [] light_snow then 2700.0   % 45 min
            [] moderate_snow then 1800.0 % 30 min
            else 2400.0
            end
         elseif TempC >= ~3.0 then
            case WeatherCondition
            of frost then 4200.0
            [] light_snow then 2100.0
            [] moderate_snow then 1200.0
            else 1800.0
            end
         else
            case WeatherCondition
            of frost then 3000.0
            [] light_snow then 1500.0
            [] moderate_snow then 900.0
            else 1200.0
            end
         end

      [] fluid_type_iv then
         % Type IV advanced prolonged holdover
         if TempC >= 0.0 then
            case WeatherCondition
            of frost then 7200.0        % 120 min
            [] light_snow then 3600.0   % 60 min
            [] moderate_snow then 2400.0 % 40 min
            else 3000.0
            end
         elseif TempC >= ~3.0 then
            case WeatherCondition
            of frost then 5400.0
            [] light_snow then 2700.0
            [] moderate_snow then 1800.0
            else 2100.0
            end
         else
            case WeatherCondition
            of frost then 3600.0
            [] light_snow then 1800.0
            [] moderate_snow then 1200.0
            else 1500.0
            end
         end

      else
         600.0
      end
   end

   % --------------------------------------------------------------------------
   % Verification of Clean Aircraft Concept
   % Returns true if planned TTOT falls strictly within the Holdover Time
   % --------------------------------------------------------------------------
   fun {IsHoldoverTimeValid TreatmentEndTime PlannedTTOT FluidType TempC WeatherCondition}
      HotSeconds = {GetHoldoverTimeSeconds FluidType TempC WeatherCondition}
      HotExpiration = TreatmentEndTime + HotSeconds
   in
      PlannedTTOT =< HotExpiration
   end

end
