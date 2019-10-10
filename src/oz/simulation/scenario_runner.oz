% =============================================================================
% Apron Batch Airfield Simulation Scenario Runner
% Module: ScenarioRunner
%
% Implements automated multi-run execution of airfield operations under varying
% traffic loads, weather conditions, and scheduling algorithms. Compares
% First-Come-First-Served (FCFS) heuristics against constraint-directed
% computation space optimization.
% =============================================================================

functor
import
    SimEngine at 'engine.oz'
    EventQueue at 'event_queue.oz'
export
    RunScenario: RunScenario
    CompareStrategies: CompareStrategies
define

    fun {RunScenario ScenarioConfig Strategy}
        Engine = {SimEngine.CreateEngine ScenarioConfig.startTime ScenarioConfig.duration}
        % Schedule flight arrival and departure events
        {ScheduleFlightEvents Engine.queue ScenarioConfig.flights}
        FinalEngine Result
    in
        Result = {SimEngine.RunUntilTime Engine ScenarioConfig.startTime + ScenarioConfig.duration
                  proc {$ Evt}
                      % Process event according to Strategy (fcfs vs constraint)
                      skip
                  end
                  FinalEngine}
        report(scenario: ScenarioConfig.name
               strategy: Strategy
               metrics: {SimEngine.GetEngineMetrics FinalEngine})
    end

    fun {ScheduleFlightEvents Queue Flights}
        case Flights
        of nil then ok
        [] F|Rest then
            _ = {EventQueue.ScheduleEvent Queue F.time 1 F}
            {ScheduleFlightEvents Queue Rest}
        end
    end

    fun {CompareStrategies ScenarioConfig}
        ResFCFS = {RunScenario ScenarioConfig 'fcfs'}
        ResCP = {RunScenario ScenarioConfig 'constraint_programming'}
    in
        comparison(scenario: ScenarioConfig.name
                   fcfs: ResFCFS
                   constraint: ResCP)
    end

end
