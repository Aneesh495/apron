% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.Logging
% Description: Structured diagnostic telemetry logging, severity level routing,
%              and asynchronous event sinks for safety and audit compliance.
% =============================================================================

functor
import
   System
   Time
export
   NewLogger: NewLogger
   Debug: LogDebug
   Info: LogInfo
   Warn: LogWarn
   Error: LogError
   Critical: LogCritical
   RecordEvent: RecordEvent
   FlushLogs: FlushLogs
define

   % --------------------------------------------------------------------------
   % Severity Levels
   % --------------------------------------------------------------------------
   LVL_DEBUG    = 10
   LVL_INFO     = 20
   LVL_WARN     = 30
   LVL_ERROR    = 40
   LVL_CRITICAL = 50

   fun {LevelToString Lvl}
      if Lvl =< LVL_DEBUG then "DEBUG"
      elseif Lvl =< LVL_INFO then "INFO"
      elseif Lvl =< LVL_WARN then "WARN"
      elseif Lvl =< LVL_ERROR then "ERROR"
      else "CRITICAL"
      end
   end

   % --------------------------------------------------------------------------
   % Logger Creation: Spawns active port thread to process log entries asynchronously
   % --------------------------------------------------------------------------
   fun {NewLogger MinLevel SubsystemTag}
      local LogStream LogPort in
         LogPort = {NewPort LogStream}
         thread
            proc {LogSink S Stats}
               case S
               of nil then skip
               [] entry(level: Lvl tag: Tag msg: Msg time: T attrs: Attrs) | Rest then
                  if Lvl >= MinLevel then
                     LevelStr = {LevelToString Lvl}
                     {System.show log(level: LevelStr
                                      subsystem: Tag
                                      time: T
                                      message: Msg
                                      details: Attrs)}
                  else
                     skip
                  end
                  NewCount = Stats.count + 1
                  NewStats = stats(count: NewCount)
               in
                  {LogSink Rest NewStats}
               [] flush(AckVar) | Rest then
                  AckVar = true
                  {LogSink Rest Stats}
               end
            end
         in
            {LogSink LogStream stats(count: 0)}
         end
         logger(port: LogPort tag: SubsystemTag minLevel: MinLevel)
      end
   end

   % --------------------------------------------------------------------------
   % Logging Dispatch Functions
   % --------------------------------------------------------------------------
   proc {LogMessage Logger Level Message Attrs}
      T = {Time.time}
   in
      {Send Logger.port entry(level: Level
                              tag: Logger.tag
                              msg: Message
                              time: T
                              attrs: Attrs)}
   end

   proc {LogDebug Logger Message Attrs}
      {LogMessage Logger LVL_DEBUG Message Attrs}
   end

   proc {LogInfo Logger Message Attrs}
      {LogMessage Logger LVL_INFO Message Attrs}
   end

   proc {LogWarn Logger Message Attrs}
      {LogMessage Logger LVL_WARN Message Attrs}
   end

   proc {LogError Logger Message Attrs}
      {LogMessage Logger LVL_ERROR Message Attrs}
   end

   proc {LogCritical Logger Message Attrs}
      {LogMessage Logger LVL_CRITICAL Message Attrs}
   end

   proc {RecordEvent Logger EventName EventPayload}
      {LogInfo Logger EventName EventPayload}
   end

   proc {FlushLogs Logger}
      local Ack in
         {Send Logger.port flush(Ack)}
         {Wait Ack}
      end
   end

end
