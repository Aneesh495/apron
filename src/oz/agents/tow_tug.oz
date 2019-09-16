% =============================================================================
% Apron Tow Tug & Ground Equipment Active Agent
% Module: TowTug
%
% Models motorized pushback tugs and towbarless ground handling vehicles.
% Manages dispatch orders, coupling to aircraft nosegear, pushback track
% execution, disconnect protocol, and return routing to equipment staging areas.
% =============================================================================

functor
import
    PushbackDynamics at '../routing/pushback.oz'
    AgentProtocol at 'protocol.oz'
export
    CreateTowTug: CreateTowTug
    DispatchTug: DispatchTug
    ExecutePushback: ExecutePushback
    CompletePushback: CompletePushback
    GetTugStatus: GetTugStatus
define

    % Tow tug operational states:
    % available, en_route, coupled, pushing, disconnecting, returning

    fun {CreateTowTug TugId BaseLocation MaxTowRating}
        InPort
        ThreadHandle

        fun {Loop Stream State}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of dispatchToStand(standId: StandId flight: FlightId reply: Reply) then
                    NewState = tug(id: TugId
                                   base: BaseLocation
                                   maxRating: MaxTowRating
                                   state: en_route
                                   currentStand: StandId
                                   currentFlight: FlightId
                                   activeTrack: nil)
                in
                    Reply = ok(tug: TugId targetStand: StandId status: en_route)
                    {Loop Rest NewState}

                [] coupleAircraft(flight: FlightId reply: Reply) then
                    NewState = tug(id: TugId
                                   base: BaseLocation
                                   maxRating: MaxTowRating
                                   state: coupled
                                   currentStand: State.currentStand
                                   currentFlight: FlightId
                                   activeTrack: nil)
                in
                    Reply = ok(tug: TugId coupledTo: FlightId status: coupled)
                    {Loop Rest NewState}

                [] startPushback(track: Track reply: Reply) then
                    NewState = tug(id: TugId
                                   base: BaseLocation
                                   maxRating: MaxTowRating
                                   state: pushing
                                   currentStand: State.currentStand
                                   currentFlight: State.currentFlight
                                   activeTrack: Track)
                in
                    Reply = ok(tug: TugId status: pushing maneuverLength: {Length Track})
                    {Loop Rest NewState}

                [] disconnectTug(reply: Reply) then
                    NewState = tug(id: TugId
                                   base: BaseLocation
                                   maxRating: MaxTowRating
                                   state: returning
                                   currentStand: none
                                   currentFlight: none
                                   activeTrack: nil)
                in
                    Reply = ok(tug: TugId status: disconnected pinRemoved: true saluteGiven: true)
                    {Loop Rest NewState}

                [] returnToBase(reply: Reply) then
                    NewState = tug(id: TugId
                                   base: BaseLocation
                                   maxRating: MaxTowRating
                                   state: available
                                   currentStand: none
                                   currentFlight: none
                                   activeTrack: nil)
                in
                    Reply = ok(tug: TugId status: available atBase: BaseLocation)
                    {Loop Rest NewState}

                [] getStatus(reply: Reply) then
                    Reply = State
                    {Loop Rest State}

                else
                    {Loop Rest State}
                end
            end
        end

        InitialState = tug(id: TugId
                           base: BaseLocation
                           maxRating: MaxTowRating
                           state: available
                           currentStand: none
                           currentFlight: none
                           activeTrack: nil)
    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort InitialState} end
        towTug(port: ThreadHandle id: TugId)
    end

    proc {DispatchTug Tug StandId FlightId ?Reply}
        {Send Tug.port dispatchToStand(standId: StandId flight: FlightId reply: Reply)}
    end

    proc {ExecutePushback Tug Track ?Reply}
        {Send Tug.port startPushback(track: Track reply: Reply)}
    end

    proc {CompletePushback Tug ?Reply}
        {Send Tug.port disconnectTug(reply: Reply)}
    end

    proc {GetTugStatus Tug ?Reply}
        {Send Tug.port getStatus(reply: Reply)}
    end

end
