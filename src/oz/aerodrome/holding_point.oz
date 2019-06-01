% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.HoldingPoint
% Description: Intermediate holding positions, runway holding points, and
%              CAT I/II/III ILS sensitive/critical area protection boundaries.
% =============================================================================

functor
export
   NewHoldingPoint: NewHoldingPoint
   IsHoldingPointActive: IsHoldingPointActive
   GetRequiredClearanceDistance: GetRequiredClearanceDistance
   IsIlsCriticalAreaViolated: IsIlsCriticalAreaViolated
define

   % --------------------------------------------------------------------------
   % Holding Point Structure:
   % hp(id: Id
   %    name: String
   %    associatedRunway: String        % Runway designator, or "NONE" for IHP
   %    category: CategoryAtom          % cat_i, cat_ii_iii, intermediate
   %    distanceToCenterlineMeters: Float
   %    ilsCriticalBoundaryMeters: Float
   %    hasSwitchableStopbar: Boolean)
   % --------------------------------------------------------------------------

   fun {NewHoldingPoint Id Name Rwy Cat DistToCenter ILSBound HasStopbar}
      hp(id: Id
         name: Name
         associatedRunway: Rwy
         category: Cat
         distanceToCenterlineMeters: DistToCenter
         ilsCriticalBoundaryMeters: ILSBound
         hasSwitchableStopbar: HasStopbar)
   end

   % --------------------------------------------------------------------------
   % Clearance Distance Requirement:
   % Low Visibility Procedures require holding farther back to protect the ILS beam
   % --------------------------------------------------------------------------
   fun {GetRequiredClearanceDistance HP IsLvpActive}
      if IsLvpActive then
         HP.ilsCriticalBoundaryMeters
      else
         HP.distanceToCenterlineMeters
      end
   end

   % --------------------------------------------------------------------------
   % Verification of ILS Critical Area Integrity
   % Returns true if aircraft position penetrates protected envelope
   % --------------------------------------------------------------------------
   fun {IsIlsCriticalAreaViolated HP AircraftDistanceToCenterline IsLvpActive}
      if IsLvpActive then
         AircraftDistanceToCenterline < HP.ilsCriticalBoundaryMeters
      else
         AircraftDistanceToCenterline < HP.distanceToCenterlineMeters
      end
   end

   fun {IsHoldingPointActive HP}
      true
   end

end
