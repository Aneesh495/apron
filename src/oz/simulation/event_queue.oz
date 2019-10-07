% =============================================================================
% Apron Discrete-Event Priority Queue Scheduler
% Module: EventQueue
%
% Implements an event priority queue ordered chronologically by scheduled
% execution time. Supports scheduling future events, canceling pending events,
% extracting the earliest due event, and advancing virtual time accordingly.
% =============================================================================

functor
export
    CreateEventQueue: CreateEventQueue
    ScheduleEvent: ScheduleEvent
    PopNextEvent: PopNextEvent
    PeekNextEventTime: PeekNextEventTime
    QueueSize: QueueSize
define

    % Event representation:
    % event(id: Int time: Int priority: Int payload: Value)

    fun {CreateEventQueue}
        InPort
        ThreadHandle

        fun {Loop Stream Queue EventCounter}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of schedule(time: T priority: P payload: Val reply: Reply) then
                    NewId = EventCounter + 1
                    Evt = event(id: NewId time: T priority: P payload: Val)
                    NewQueue = {InsertSorted Queue Evt}
                in
                    Reply = NewId
                    {Loop Rest NewQueue NewId}

                [] pop(reply: Reply) then
                    case Queue
                    of nil then
                        Reply = empty
                        {Loop Rest nil EventCounter}
                    [] Top|QueueRest then
                        Reply = event(Top)
                        {Loop Rest QueueRest EventCounter}
                    end

                [] peekTime(reply: Reply) then
                    case Queue
                    of nil then Reply = none
                    [] Top|_ then Reply = Top.time
                    end
                    {Loop Rest Queue EventCounter}

                [] size(reply: Reply) then
                    Reply = {Length Queue}
                    {Loop Rest Queue EventCounter}

                else
                    {Loop Rest Queue EventCounter}
                end
            end
        end

        fun {InsertSorted List Item}
            case List
            of nil then [Item]
            [] H|T then
                if Item.time < H.time then
                    Item|List
                else
                    if Item.time == H.time andthen Item.priority < H.priority then
                        Item|List
                    else
                        H|{InsertSorted T Item}
                    end
                end
            end
        end

    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort nil 0} end
        eventQueue(port: ThreadHandle)
    end

    proc {ScheduleEvent Q Time Priority Payload ?EventId}
        {Send Q.port schedule(time: Time priority: Priority payload: Payload reply: EventId)}
    end

    proc {PopNextEvent Q ?Result}
        {Send Q.port pop(reply: Result)}
    end

    proc {PeekNextEventTime Q ?Time}
        {Send Q.port peekTime(reply: Time)}
    end

    proc {QueueSize Q ?Size}
        {Send Q.port size(reply: Size)}
    end

end
