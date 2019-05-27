% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Stand
% Description: Contact and remote parking stand definitions, passenger boarding
%              bridge configurations, and apron pushback conflict envelopes.
% =============================================================================

functor
export
   NewStand: NewStand
   IsStandCompatible: IsStandCompatible
   GetBlockedStandsOnPushback: GetBlockedStandsOnPushback
   HasPassengerBoardingBridge: HasPassengerBoardingBridge
   HasUndergroundFuelHydrant: HasUndergroundFuelHydrant
define

   % --------------------------------------------------------------------------
   % Stand Definition:
   % stand(id: Id
   %       terminal: String
   %       isContact: Boolean        % True if equipped with Jetbridge / PBB
   %       maxCode: CodeLetter       % ICAO code A-F
   %       maxWingspanMeters: Float
   %       maxLenMeters: Float
   %       isSchengen: Boolean
   %       hasGpu400Hz: Boolean
   %       hasHydrantFuel: Boolean
   %       blockedStands: ListOfStandIds)  % Stands blocked during pushback
   % --------------------------------------------------------------------------

   fun {NewStand Id Terminal Contact MaxCode Wingspan Len Schengen Gpu Fuel Blocked}
      stand(id: Id
            terminal: Terminal
            isContact: Contact
            maxCode: MaxCode
            maxWingspanMeters: Wingspan
            maxLenMeters: Len
            isSchengen: Schengen
            hasGpu400Hz: Gpu
            hasHydrantFuel: Fuel
            blockedStands: Blocked)
   end

   % --------------------------------------------------------------------------
   % Compatibility Predicate: Verifies physical aircraft dimensions
   % --------------------------------------------------------------------------
   fun {IsStandCompatible Stand AircraftWingspan AircraftLength AircraftIsSchengen}
      if AircraftWingspan > Stand.maxWingspanMeters then
         false
      elseif AircraftLength > Stand.maxLenMeters then
         false
      elseif AircraftIsSchengen andthen (Stand.isSchengen == false) then
         false
      else
         true
      end
   end

   fun {GetBlockedStandsOnPushback Stand}
      Stand.blockedStands
   end

   fun {HasPassengerBoardingBridge Stand}
      Stand.isContact
   end

   fun {HasUndergroundFuelHydrant Stand}
      Stand.hasHydrantFuel
   end

end
