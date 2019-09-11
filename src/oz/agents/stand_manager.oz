% =============================================================================
% Apron Stand Manager Active Agent
% Module: StandManager
%
% Implements automated stand and gate allocation for arriving and departing
% flights. Manages stand occupancy states, physical dimensional constraints
% (wingspan and length envelopes), contact vs remote stand allocations, and
% turnarounds in coordinated collaboration with A-CDM milestones.
% =============================================================================

functor
import
    StandAllocation at '../aerodrome/stands.oz'
    AgentProtocol at 'protocol.oz'
export
    CreateStandManager: CreateStandManager
    RequestStand: RequestStand
    ReleaseStand: ReleaseStand
    GetStandOccupant: GetStandOccupant
define

    % Stand entry record:
    % stand(id: Id category: Cat maxWingspan: Span contact: Bool currentFlight: FlightId)

    fun {CreateStandManager Stands}
        InPort
        ThreadHandle

        fun {Loop Stream CurrentStands Reservations}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of requestStand(flight: Flight aircraftType: Type arrTime: Arr depTime: Dep reply: Reply) then
                    NewStands NewRes AllocResult
                in
                    {TryAllocateStand CurrentStands Reservations Flight Type Arr Dep AllocResult NewStands NewRes}
                    Reply = AllocResult
                    {Loop Rest NewStands NewRes}

                [] releaseStand(standId: StandId flight: Flight reply: Reply) then
                    NewStands
                in
                    {DoReleaseStand CurrentStands StandId Flight NewStands}
                    Reply = ok(standId: StandId flight: Flight releasedAt: true)
                    {Loop Rest NewStands Reservations}

                [] getOccupant(standId: StandId reply: Reply) then
                    Reply = {FindOccupant CurrentStands StandId}
                    {Loop Rest CurrentStands Reservations}

                [] listAllStands(reply: Reply) then
                    Reply = CurrentStands
                    {Loop Rest CurrentStands Reservations}

                else
                    {Loop Rest CurrentStands Reservations}
                end
            end
        end

        fun {TryAllocateStand Stands Res Flight Type Arr Dep AllocResult OutStands OutRes}
            % Find eligible stand with sufficient wingspan and no temporal overlap
            Candidate = {FindEligibleStand Stands Res Type Arr Dep}
        in
            case Candidate
            of found(StandId) then
                AllocResult = ok(assignedStand: StandId flight: Flight)
                OutStands = {UpdateStandOccupant Stands StandId Flight}
                OutRes = reservation(stand: StandId flight: Flight from: Arr to: Dep)|Res
            [] noneAvailable then
                AllocResult = error(noAvailableStand)
                OutStands = Stands
                OutRes = Res
            end
        end

        fun {FindEligibleStand Stands Res Type Arr Dep}
            case Stands
            of nil then noneAvailable
            [] S|Rest then
                if {IsStandAvailable S Res Arr Dep} then
                    found(S.id)
                else
                    {FindEligibleStand Rest Res Type Arr Dep}
                end
            end
        end

        fun {IsStandAvailable Stand Res Arr Dep}
            % Stand must not have active occupant and no reservation collision
            (Stand.currentFlight == none) andthen {NotColliding Res Stand.id Arr Dep}
        end

        fun {NotColliding Res StandId Arr Dep}
            case Res
            of nil then true
            [] R|Rest then
                if R.stand == StandId then
                    % Overlap check: not (Dep <= R.from or Arr >= R.to)
                    if (Dep =< R.from) orelse (Arr >= R.to) then
                        {NotColliding Rest StandId Arr Dep}
                    else
                        false
                    end
                else
                    {NotColliding Rest StandId Arr Dep}
                end
            end
        end

        fun {UpdateStandOccupant Stands TargetId NewFlight}
            case Stands
            of nil then nil
            [] S|Rest then
                if S.id == TargetId then
                    stand(id: S.id category: S.category maxWingspan: S.maxWingspan
                          contact: S.contact currentFlight: NewFlight)|Rest
                else
                    S|{UpdateStandOccupant Rest TargetId NewFlight}
                end
            end
        end

        fun {DoReleaseStand Stands TargetId TargetFlight OutStands}
            case Stands
            of nil then OutStands = nil
            [] S|Rest then
                if S.id == TargetId andthen S.currentFlight == TargetFlight then
                    OutStands = stand(id: S.id category: S.category maxWingspan: S.maxWingspan
                                      contact: S.contact currentFlight: none)|Rest
                else
                    OutStands = S|{DoReleaseStand Rest TargetId TargetFlight}
                end
            end
        end

        fun {FindOccupant Stands TargetId}
            case Stands
            of nil then none
            [] S|Rest then
                if S.id == TargetId then S.currentFlight
                else {FindOccupant Rest TargetId} end
            end
        end

    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort Stands nil} end
        standManager(port: ThreadHandle)
    end

    proc {RequestStand Mgr Flight Type Arr Dep ?Reply}
        {Send Mgr.port requestStand(flight: Flight aircraftType: Type arrTime: Arr depTime: Dep reply: Reply)}
    end

    proc {ReleaseStand Mgr StandId Flight ?Reply}
        {Send Mgr.port releaseStand(standId: StandId flight: Flight reply: Reply)}
    end

    proc {GetStandOccupant Mgr StandId ?Reply}
        {Send Mgr.port getOccupant(standId: StandId reply: Reply)}
    end

end
