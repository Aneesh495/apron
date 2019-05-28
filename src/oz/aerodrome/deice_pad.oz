% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.DeicePad
% Description: Centralized de-icing pad clusters, treatment bay configurations,
%              glycol fluid capacities, and queue progression models.
% =============================================================================

functor
export
   NewDeiceFacility: NewDeiceFacility
   GetEstimatedDeicingDuration: GetEstimatedDeicingDuration
   IsPadAvailable: IsPadAvailable
   AllocateBay: AllocateBay
   ReleaseBay: ReleaseBay
define

   % --------------------------------------------------------------------------
   % De-icing Facility Definition:
   % facility(id: Id
   %          name: String
   %          clusterLocation: LocationAtom  % e.g. holding_point_27l, apron_north
   %          totalBays: Integer
   %          occupiedBays: Integer
   %          supportedCodes: ListOfCodes
   %          glycolRecoveryActive: Boolean)
   % --------------------------------------------------------------------------

   fun {NewDeiceFacility Id Name Loc TotalBays SupportedCodes GlycolRec}
      facility(id: Id
               name: Name
               clusterLocation: Loc
               totalBays: TotalBays
               occupiedBays: 0
               supportedCodes: SupportedCodes
               glycolRecoveryActive: GlycolRec)
   end

   % --------------------------------------------------------------------------
   % Treatment Duration Estimation (seconds)
   % --------------------------------------------------------------------------
   fun {GetEstimatedDeicingDuration AircraftCode WeatherCondition}
      BaseSeconds = case AircraftCode
                    of code_f then 1200.0  % 20 minutes for A380
                    [] code_e then 900.0   % 15 minutes for B777
                    [] code_d then 720.0   % 12 minutes for B757
                    [] code_c then 480.0   % 8 minutes for A320
                    [] code_b then 360.0
                    [] code_a then 300.0
                    else 480.0
                    end
      Multiplier = case WeatherCondition
                   of frost then 1.0
                   [] light_snow then 1.3
                   [] moderate_snow then 1.6
                   [] freezing_rain then 2.0
                   else 1.0
                   end
   in
      BaseSeconds * Multiplier
   end

   fun {IsPadAvailable Fac}
      Fac.occupiedBays < Fac.totalBays
   end

   fun {AllocateBay Fac}
      if {IsPadAvailable Fac} then
         facility(id: Fac.id
                  name: Fac.name
                  clusterLocation: Fac.clusterLocation
                  totalBays: Fac.totalBays
                  occupiedBays: Fac.occupiedBays + 1
                  supportedCodes: Fac.supportedCodes
                  glycolRecoveryActive: Fac.glycolRecoveryActive)
      else
         Fac
      end
   end

   fun {ReleaseBay Fac}
      if Fac.occupiedBays > 0 then
         facility(id: Fac.id
                  name: Fac.name
                  clusterLocation: Fac.clusterLocation
                  totalBays: Fac.totalBays
                  occupiedBays: Fac.occupiedBays - 1
                  supportedCodes: Fac.supportedCodes
                  glycolRecoveryActive: Fac.glycolRecoveryActive)
      else
         Fac
      end
   end

end
