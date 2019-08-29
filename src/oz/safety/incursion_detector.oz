% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Safety.IncursionDetector
% Description: Stopbar breach detection, unauthorized runway entry monitoring,
%              and radar blind-spot tracking coverage verification.
% =============================================================================

functor
export
   CheckStopbarBreach: CheckStopbarBreach
   CheckUnauthorizedLineUp: CheckUnauthorizedLineUp
   IsTargetInRadarBlindSpot: IsTargetInRadarBlindSpot
define

   % --------------------------------------------------------------------------
   % CheckStopbarBreach: Detects aircraft moving past an illuminated RED stopbar
   % --------------------------------------------------------------------------
   fun {CheckStopbarBreach AircraftTarget AssociatedStopbar}
      if AssociatedStopbar.state == stopbar_red andthen AircraftTarget.hasCrossedHoldingLine then
         breach(isBreached: true
                callsign: AircraftTarget.callsign
                stopbarId: AssociatedStopbar.id
                severity: critical
                message: "STOPBAR BREACH: Unauthorized movement across red holding line")
      else
         breach(isBreached: false
                callsign: AircraftTarget.callsign
                stopbarId: AssociatedStopbar.id
                severity: none
                message: "OK")
      end
   end

   % --------------------------------------------------------------------------
   % CheckUnauthorizedLineUp: Aircraft enters runway box without ATC line-up clearance
   % --------------------------------------------------------------------------
   fun {CheckUnauthorizedLineUp AircraftTarget HasLineUpClearance RunwayBox}
      InsideX = (AircraftTarget.x >= RunwayBox.minX) andthen (AircraftTarget.x =< RunwayBox.maxX)
      InsideY = (AircraftTarget.y >= RunwayBox.minY) andthen (AircraftTarget.y =< RunwayBox.maxY)
   in
      if InsideX andthen InsideY andthen (HasLineUpClearance == false) then
         unauthorized_entry(detected: true
                            callsign: AircraftTarget.callsign
                            message: "UNAUTHORIZED LINE-UP: Aircraft on runway without clearance")
      else
         unauthorized_entry(detected: false callsign: AircraftTarget.callsign message: "OK")
      end
   end

   % --------------------------------------------------------------------------
   % Radar Blind-Spot Check: Verifies whether position falls inside sensor shadow
   % --------------------------------------------------------------------------
   fun {IsTargetInRadarBlindSpot Pt BlindSpotPolygons}
      fun {CheckPolys Polys}
         case Polys
         of nil then false
         [] Poly | Rest then
            % Simple bounding box check for polygon shadow
            InX = (Pt.x >= Poly.minX) andthen (Pt.x =< Poly.maxX)
            InY = (Pt.y >= Poly.minY) andthen (Pt.y =< Poly.maxY)
         in
            if InX andthen InY then true else {CheckPolys Rest} end
         end
      end
   in
      {CheckPolys BlindSpotPolygons}
   end

end
