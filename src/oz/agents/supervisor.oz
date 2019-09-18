% =============================================================================
% Apron Master Airfield Supervisor & Orchestrator Agent
% Module: AirfieldSupervisor
%
% Implements the root coordinating agent that oversees Tower ATC, Ground ATC,
% Stand Management, Cockpit Agents, and Ground Support Equipment. Provides
% unified lifecycle event orchestration, Low Visibility Procedures (LVP)
% management, emergency stop broadcasting, and A-CDM system metrics.
% =============================================================================

functor
import
    TowerATC at 'tower_atc.oz'
    GroundATC at 'apron_ground.oz'
    StandMgr at 'stand_manager.oz'
    AgentProtocol at 'protocol.oz'
export
    CreateSupervisor: CreateSupervisor
    RegisterFlight: RegisterFlight
    TriggerLVP: TriggerLVP
    EmergencyStop: EmergencyStop
    GetAirfieldSnapshot: GetAirfieldSnapshot
define

    % Operational modes: normal_ops, low_visibility_lvp, emergency_stop

    fun {CreateSupervisor Tower Ground Stands Config}
        InPort
        ThreadHandle

        fun {Loop Stream State}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of registerFlight(flightId: FId type: Type stand: Stand runway: Rwy reply: Reply) then
                    NewRoster = flightEntry(id: FId type: Type stand: Stand runway: Rwy status: active)|State.roster
                    NewState = supervisor(tower: State.tower
                                          ground: State.ground
                                          stands: State.stands
                                          mode: State.mode
                                          roster: NewRoster
                                          clock: State.clock)
                in
                    Reply = ok(registered: FId currentActive: {Length NewRoster})
                    {Loop Rest NewState}

                [] setOperationalMode(mode: NewMode reply: Reply) then
                    NewState = supervisor(tower: State.tower
                                          ground: State.ground
                                          stands: State.stands
                                          mode: NewMode
                                          roster: State.roster
                                          clock: State.clock)
                in
                    Reply = ok(previousMode: State.mode currentMode: NewMode)
                    {Loop Rest NewState}

                [] advanceClock(seconds: Delta reply: Reply) then
                    NewClock = State.clock + Delta
                    NewState = supervisor(tower: State.tower
                                          ground: State.ground
                                          stands: State.stands
                                          mode: State.mode
                                          roster: State.roster
                                          clock: NewClock)
                in
                    Reply = ok(currentTime: NewClock)
                    {Loop Rest NewState}

                [] getSnapshot(reply: Reply) then
                    Reply = snapshot(mode: State.mode
                                     clock: State.clock
                                     activeFlights: {Length State.roster}
                                     roster: State.roster)
                    {Loop Rest State}

                [] emergencyStop(reason: Reason reply: Reply) then
                    NewState = supervisor(tower: State.tower
                                          ground: State.ground
                                          stands: State.stands
                                          mode: emergency_stop
                                          roster: State.roster
                                          clock: State.clock)
                in
                    Reply = broadcast(action: haltAllMovements reason: Reason time: State.clock)
                    {Loop Rest NewState}

                else
                    {Loop Rest State}
                end
            end
        end

        InitialState = supervisor(tower: Tower
                                  ground: Ground
                                  stands: Stands
                                  mode: normal_ops
                                  roster: nil
                                  clock: 0)
    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort InitialState} end
        supervisor(port: ThreadHandle)
    end

    proc {RegisterFlight Sup FId Type Stand Rwy ?Reply}
        {Send Sup.port registerFlight(flightId: FId type: Type stand: Stand runway: Rwy reply: Reply)}
    end

    proc {TriggerLVP Sup Enable ?Reply}
        Mode = if Enable then low_visibility_lvp else normal_ops end
    in
        {Send Sup.port setOperationalMode(mode: Mode reply: Reply)}
    end

    proc {EmergencyStop Sup Reason ?Reply}
        {Send Sup.port emergencyStop(reason: Reason reply: Reply)}
    end

    proc {GetAirfieldSnapshot Sup ?Reply}
        {Send Sup.port getSnapshot(reply: Reply)}
    end

end
