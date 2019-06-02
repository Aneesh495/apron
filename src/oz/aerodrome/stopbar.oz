% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Aerodrome.Stopbar
% Description: Addressable airfield ground lighting (AGL) stopbar control logic,
%              safety interlocks, runway incursion prevention, and auto-reset FSM.
% =============================================================================

functor
export
   STOPBAR_RED: STOPBAR_RED
   STOPBAR_GREEN: STOPBAR_GREEN
   STOPBAR_FLASHING: STOPBAR_FLASHING
   NewStopbar: NewStopbar
   RequestClearance: RequestClearance
   OnSensorCrossed: OnSensorCrossed
   TriggerIncursionAlert: TriggerIncursionAlert
define

   STOPBAR_RED      = stopbar_red
   STOPBAR_GREEN    = stopbar_green
   STOPBAR_FLASHING = stopbar_flashing

   % --------------------------------------------------------------------------
   % Stopbar Structure:
   % stopbar(id: Id
   %         associatedHoldingPoint: Id
   %         state: StateAtom
   %         isRunwayOccupied: Boolean
   %         autoResetDelaySec: Float
   %         lastSwitchTimestamp: Float)
   % --------------------------------------------------------------------------

   fun {NewStopbar Id HpId}
      stopbar(id: Id
              associatedHoldingPoint: HpId
              state: STOPBAR_RED
              isRunwayOccupied: false
              autoResetDelaySec: 2.0
              lastSwitchTimestamp: 0.0)
   end

   % --------------------------------------------------------------------------
   % RequestClearance: Tower controller clears stopbar to GREEN
   % Interlock: Rejects request if runway is occupied by landing/departing aircraft
   % --------------------------------------------------------------------------
   fun {RequestClearance SB CurrentTime RunwayOccupied}
      if RunwayOccupied then
         % Interlock active: cannot drop stopbar into occupied runway
         SB
      else
         stopbar(id: SB.id
                 associatedHoldingPoint: SB.associatedHoldingPoint
                 state: STOPBAR_GREEN
                 isRunwayOccupied: false
                 autoResetDelaySec: SB.autoResetDelaySec
                 lastSwitchTimestamp: CurrentTime)
      end
   end

   % --------------------------------------------------------------------------
   % OnSensorCrossed: Induction loop or radar detects aircraft nose crossing bar
   % Automatically reverts stopbar to RED to protect following aircraft
   % --------------------------------------------------------------------------
   fun {OnSensorCrossed SB CurrentTime}
      stopbar(id: SB.id
              associatedHoldingPoint: SB.associatedHoldingPoint
              state: STOPBAR_RED
              isRunwayOccupied: true
              autoResetDelaySec: SB.autoResetDelaySec
              lastSwitchTimestamp: CurrentTime)
   end

   % --------------------------------------------------------------------------
   % Incursion Alert: Flashes stopbar red and triggers siren
   % --------------------------------------------------------------------------
   fun {TriggerIncursionAlert SB CurrentTime}
      stopbar(id: SB.id
              associatedHoldingPoint: SB.associatedHoldingPoint
              state: STOPBAR_FLASHING
              isRunwayOccupied: true
              autoResetDelaySec: SB.autoResetDelaySec
              lastSwitchTimestamp: CurrentTime)
   end

end
