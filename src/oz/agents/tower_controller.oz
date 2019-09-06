% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Agents.TowerController
% Description: Active port-based Tower Air Traffic Controller agent managing active
%              runway clearances, line-up authorizations, and wake vortex spacing.
% =============================================================================

functor
import
   System
   WakeMatrix at '../sequencing/wake_matrix.oz'
export
   SpawnTowerController: SpawnTowerController
define

   % --------------------------------------------------------------------------
   % SpawnTowerController: Starts concurrent Tower ATC agent listening on Port
   % --------------------------------------------------------------------------
   fun {SpawnTowerController RunwayId}
      local InStream Port in
         Port = {NewPort InStream}
         thread
            proc {EventLoop Stream State}
               case Stream
               of nil then skip

               [] msg_request_lineup(flightId: F runwayId: R ack: Ack) | Rest then
                  if R == RunwayId andthen State.isRunwayFree then
                     Ack = approved(runway: R lineupTime: State.clock)
                     NewState = tower_state(isRunwayFree: false
                                            lastDepartedFlight: F
                                            lastRollTime: State.clock
                                            clock: State.clock)
                  in
                     {EventLoop Rest NewState}
                  else
                     Ack = hold_short(runway: R reason: runway_busy)
                     {EventLoop Rest State}
                  end

               [] msg_clear_takeoff(flightId: F runwayId: R assignedHeadingDeg: _ surfaceWindKts: _) | Rest then
                  NewState = tower_state(isRunwayFree: false
                                         lastDepartedFlight: F
                                         lastRollTime: State.clock
                                         clock: State.clock)
               in
                  {EventLoop Rest NewState}

               [] msg_report_vacated(flightId: _ runwayId: R exitNode: _) | Rest then
                  if R == RunwayId then
                     NewState = tower_state(isRunwayFree: true
                                            lastDepartedFlight: State.lastDepartedFlight
                                            lastRollTime: State.lastRollTime
                                            clock: State.clock)
                  in
                     {EventLoop Rest NewState}
                  else
                     {EventLoop Rest State}
                  end

               [] tick(CurrentTime) | Rest then
                  NewState = tower_state(isRunwayFree: State.isRunwayFree
                                         lastDepartedFlight: State.lastDepartedFlight
                                         lastRollTime: State.lastRollTime
                                         clock: CurrentTime)
               in
                  {EventLoop Rest NewState}
               end
            end
            InitialState = tower_state(isRunwayFree: true
                                       lastDepartedFlight: none
                                       lastRollTime: 0.0
                                       clock: 0.0)
         in
            {EventLoop InStream InitialState}
         end
         tower_agent(port: Port runwayId: RunwayId)
      end
   end

end
