% =============================================================================
% Apron Flight Crew Cockpit Active Agent
% Module: FlightCrew
%
% Implements the cockpit autonomous decision agent representing the aircraft
% flight crew. Simulates pre-flight preparations, TOBT readiness declarations,
% startup and pushback negotiation, taxi clearance compliance, intermediate
% hold execution, and takeoff roll initiation.
% =============================================================================

functor
import
    AgentProtocol at 'protocol.oz'
export
    CreateFlightCrew: CreateFlightCrew
    DeclareReady: DeclareReady
    ReceiveClearance: ReceiveClearance
    GetCockpitState: GetCockpitState
define

    % Flight crew phase enumerations:
    % preflight, boarding, ready_for_push, pushback_active, taxi_out,
    % hold_short_runway, lineup_and_wait, takeoff_roll, airborne

    fun {CreateFlightCrew FlightId AircraftType Origin Dest StandId}
        InPort
        ThreadHandle

        fun {Loop Stream State}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of declareReady(tobt: TOBT reply: Reply) then
                    NewState = cockpit(flight: FlightId
                                       type: AircraftType
                                       stand: StandId
                                       phase: ready_for_push
                                       tobt: TOBT
                                       currentRoute: State.currentRoute
                                       assignedRunway: State.assignedRunway)
                in
                    Reply = ok(flight: FlightId status: ready_for_push)
                    {Loop Rest NewState}

                [] receiveClearance(clearanceType: Type details: Details reply: Reply) then
                    NewState
                in
                    case Type
                    of startup_pushback then
                        NewState = cockpit(flight: FlightId
                                           type: AircraftType
                                           stand: StandId
                                           phase: pushback_active
                                           tobt: State.tobt
                                           currentRoute: State.currentRoute
                                           assignedRunway: Details.assignedRunway)
                        Reply = readback(flight: FlightId type: Type status: acknowledged)

                    [] taxi then
                        NewState = cockpit(flight: FlightId
                                           type: AircraftType
                                           stand: StandId
                                           phase: taxi_out
                                           tobt: State.tobt
                                           currentRoute: Details.route
                                           assignedRunway: State.assignedRunway)
                        Reply = readback(flight: FlightId type: Type route: Details.route)

                    [] hold_short then
                        NewState = cockpit(flight: FlightId
                                           type: AircraftType
                                           stand: StandId
                                           phase: hold_short_runway
                                           tobt: State.tobt
                                           currentRoute: State.currentRoute
                                           assignedRunway: State.assignedRunway)
                        Reply = readback(flight: FlightId type: Type holdingPoint: Details.point)

                    [] cleared_takeoff then
                        NewState = cockpit(flight: FlightId
                                           type: AircraftType
                                           stand: StandId
                                           phase: takeoff_roll
                                           tobt: State.tobt
                                           currentRoute: nil
                                           assignedRunway: State.assignedRunway)
                        Reply = readback(flight: FlightId type: Type status: rolling)

                    else
                        NewState = State
                        Reply = readback(flight: FlightId type: Type status: unknown_clearance)
                    end
                    {Loop Rest NewState}

                [] getState(reply: Reply) then
                    Reply = State
                    {Loop Rest State}

                else
                    {Loop Rest State}
                end
            end
        end

        InitialState = cockpit(flight: FlightId
                               type: AircraftType
                               stand: StandId
                               phase: preflight
                               tobt: 0
                               currentRoute: nil
                               assignedRunway: none)
    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort InitialState} end
        flightCrew(port: ThreadHandle flight: FlightId)
    end

    proc {DeclareReady Crew TOBT ?Reply}
        {Send Crew.port declareReady(tobt: TOBT reply: Reply)}
    end

    proc {ReceiveClearance Crew Type Details ?Reply}
        {Send Crew.port receiveClearance(clearanceType: Type details: Details reply: Reply)}
    end

    proc {GetCockpitState Crew ?Reply}
        {Send Crew.port getState(reply: Reply)}
    end

end
