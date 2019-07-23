% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Sequencing.RecatEU
% Description: Eurocontrol RECAT-EU 6-category wake vortex classification engine
%              mapping ICAO type designators, MTOW, and wingspans to CAT-A through CAT-F.
% =============================================================================

functor
export
   CAT_A: CAT_A
   CAT_B: CAT_B
   CAT_C: CAT_C
   CAT_D: CAT_D
   CAT_E: CAT_E
   CAT_F: CAT_F
   ClassifyAircraftType: ClassifyAircraftType
   ClassifyByDimensions: ClassifyByDimensions
define

   CAT_A = cat_a  % Super Heavy (A380-800, An-225)
   CAT_B = cat_b  % Upper Heavy (B777, B747, A350, A340-500/600)
   CAT_C = cat_c  % Lower Heavy (B787, B767, A330, A300, A340-200/300)
   CAT_D = cat_d  % Upper Medium (B757, B737-700/800/900/MAX, A320/A321)
   CAT_E = cat_e  % Lower Medium (E190/195, A220, CRJ-700/900/1000, ATR-72, Q400)
   CAT_F = cat_f  % Light (Cessna Citation, King Air, general aviation MTOW <= 15t)

   % --------------------------------------------------------------------------
   % ClassifyByDimensions: Evaluates MTOW (tonnes) and wingspan (meters)
   % --------------------------------------------------------------------------
   fun {ClassifyByDimensions MtowTonnes WingspanMeters}
      if MtowTonnes >= 100.0 then
         if WingspanMeters >= 72.0 then
            CAT_A
         elseif WingspanMeters >= 60.0 then
            CAT_B
         else
            CAT_C
         end
      elseif MtowTonnes > 15.0 then
         if WingspanMeters >= 32.0 then
            CAT_D
         else
            CAT_E
         end
      else
         CAT_F
      end
   end

   % --------------------------------------------------------------------------
   % Comprehensive Lookup Table for ICAO Aircraft Designators
   % --------------------------------------------------------------------------
   fun {ClassifyAircraftType Designator}
      case Designator
      % CAT-A: Super Heavy
      of "A388" then CAT_A
      [] "A225" then CAT_A

      % CAT-B: Upper Heavy
      [] "B772" then CAT_B
      [] "B773" then CAT_B
      [] "B77W" then CAT_B
      [] "B77L" then CAT_B
      [] "B778" then CAT_B
      [] "B779" then CAT_B
      [] "B744" then CAT_B
      [] "B748" then CAT_B
      [] "A359" then CAT_B
      [] "A35K" then CAT_B
      [] "A345" then CAT_B
      [] "A346" then CAT_B

      % CAT-C: Lower Heavy
      [] "B788" then CAT_C
      [] "B789" then CAT_C
      [] "B78X" then CAT_C
      [] "B762" then CAT_C
      [] "B763" then CAT_C
      [] "B764" then CAT_C
      [] "A332" then CAT_C
      [] "A333" then CAT_C
      [] "A338" then CAT_C
      [] "A339" then CAT_C
      [] "A306" then CAT_C
      [] "A310" then CAT_C
      [] "A342" then CAT_C
      [] "A343" then CAT_C
      [] "MD11" then CAT_C
      [] "DC10" then CAT_C

      % CAT-D: Upper Medium
      [] "B752" then CAT_D
      [] "B753" then CAT_D
      [] "B737" then CAT_D
      [] "B738" then CAT_D
      [] "B739" then CAT_D
      [] "B37M" then CAT_D
      [] "B38M" then CAT_D
      [] "B39M" then CAT_D
      [] "A319" then CAT_D
      [] "A320" then CAT_D
      [] "A321" then CAT_D
      [] "A20N" then CAT_D
      [] "A21N" then CAT_D
      [] "C919" then CAT_D
      [] "T204" then CAT_D

      % CAT-E: Lower Medium
      [] "BCS1" then CAT_E  % A220-100
      [] "BCS3" then CAT_E  % A220-300
      [] "E170" then CAT_E
      [] "E175" then CAT_E
      [] "E190" then CAT_E
      [] "E195" then CAT_E
      [] "E290" then CAT_E
      [] "E295" then CAT_E
      [] "CRJ7" then CAT_E
      [] "CRJ9" then CAT_E
      [] "CRJX" then CAT_E
      [] "AT45" then CAT_E
      [] "AT72" then CAT_E
      [] "DH8D" then CAT_E  % Dash 8-Q400
      [] "SF34" then CAT_E

      % CAT-F: Light
      [] "C550" then CAT_F
      [] "C560" then CAT_F
      [] "C680" then CAT_F
      [] "BE20" then CAT_F  % King Air
      [] "BE9L" then CAT_F
      [] "PC12" then CAT_F
      [] "PA34" then CAT_F
      [] "C172" then CAT_F
      [] "C182" then CAT_F
      [] "SR22" then CAT_F

      else
         CAT_D  % Default to Upper Medium
      end
   end

end
