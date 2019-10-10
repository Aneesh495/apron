% =============================================================================
% Apron Discrete-Event Simulation Engine
% Module: SimulationEngine
%
% Implements the master discrete-event simulation kernel. Coordinates virtual
% clock stepping, event queue dispatching, state snapshot generation, and
% multi-agent airfield simulation runs.
% =============================================================================

functor
import
    SimClock at 'clock.oz'
    EventQueue at 'event_queue.oz'
export
    CreateEngine: CreateEngine
    StepEngine: StepEngine
    RunUntilTime: RunUntilTime
    GetEngineMetrics: GetEngineMetrics
define

    fun {CreateEngine InitialTime MaxHorizon}
        Clock = {SimClock.CreateClock InitialTime}
        Queue = {EventQueue.CreateEventQueue}
    in
        engine(clock: Clock queue: Queue horizon: MaxHorizon processedEvents: 0)
    end

    % Steps the simulation to the next scheduled event in the event queue
    fun {StepEngine Engine HandlerProc OutEngine}
        Result
    in
        {EventQueue.PopNextEvent Engine.queue Result}
        case Result
        of empty then
            OutEngine = Engine
            no_more_events
        [] event(Evt) then
            CurrentTime
        in
            {SimClock.SetTime Engine.clock Evt.time _}
            {HandlerProc Evt}
            OutEngine = engine(clock: Engine.clock
                               queue: Engine.queue
                               horizon: Engine.horizon
                               processedEvents: Engine.processedEvents + 1)
            event_processed(Evt.id)
        end
    end

    % Runs simulation iteratively until specified target epoch or queue emptiness
    fun {RunUntilTime Engine TargetEpoch HandlerProc OutEngine}
        NextTime
    in
        {EventQueue.PeekNextEventTime Engine.queue NextTime}
        case NextTime
        of none then
            OutEngine = Engine
            completed(reason: queue_empty)
        [] T then
            if T > TargetEpoch then
                OutEngine = Engine
                completed(reason: horizon_reached)
            else
                StepEngineRes StepOut
            in
                StepEngineRes = {StepEngine Engine HandlerProc StepOut}
                {RunUntilTime StepOut TargetEpoch HandlerProc OutEngine}
            end
        end
    end

    fun {GetEngineMetrics Engine}
        CurrentTime
        PendingCount
    in
        {SimClock.GetTime Engine.clock CurrentTime}
        {EventQueue.QueueSize Engine.queue PendingCount}
        metrics(currentTime: CurrentTime
                eventsProcessed: Engine.processedEvents
                eventsPending: PendingCount)
    end

end
