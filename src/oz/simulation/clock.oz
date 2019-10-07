% =============================================================================
% Apron Discrete-Event Simulation Clock
% Module: SimulationClock
%
% Implements the virtual simulation clock supporting variable speed factors,
% discrete epoch jumps, step advancement, and synchronized agent time ticks.
% =============================================================================

functor
export
    CreateClock: CreateClock
    AdvanceClock: AdvanceClock
    SetTime: SetTime
    GetTime: GetTime
    FormatClockTime: FormatClockTime
define

    fun {CreateClock InitialEpoch}
        InPort
        ThreadHandle

        fun {Loop Stream CurrentEpoch}
            case Stream of nil then ok
            [] Msg|Rest then
                case Msg
                of advance(delta: Delta reply: Reply) then
                    NewEpoch = CurrentEpoch + Delta
                in
                    Reply = NewEpoch
                    {Loop Rest NewEpoch}

                [] set(epoch: NewEpoch reply: Reply) then
                    Reply = ok(previous: CurrentEpoch current: NewEpoch)
                    {Loop Rest NewEpoch}

                [] get(reply: Reply) then
                    Reply = CurrentEpoch
                    {Loop Rest CurrentEpoch}

                else
                    {Loop Rest CurrentEpoch}
                end
            end
        end
    in
        {NewPort InPort ThreadHandle}
        thread {Loop InPort InitialEpoch} end
        simClock(port: ThreadHandle)
    end

    proc {AdvanceClock Clock Delta ?NewTime}
        {Send Clock.port advance(delta: Delta reply: NewTime)}
    end

    proc {SetTime Clock Epoch ?Reply}
        {Send Clock.port set(epoch: Epoch reply: Reply)}
    end

    proc {GetTime Clock ?Epoch}
        {Send Clock.port get(reply: Epoch)}
    end

    fun {FormatClockTime Seconds}
        Hours = (Seconds div 3600) mod 24
        Mins = (Seconds mod 3600) div 60
        Secs = Seconds mod 60
        HStr = if Hours < 10 then "0" # {IntToString Hours} else {IntToString Hours} end
        MStr = if Mins < 10 then "0" # {IntToString Mins} else {IntToString Mins} end
        SStr = if Secs < 10 then "0" # {IntToString Secs} else {IntToString Secs} end
    in
        HStr # ":" # MStr # ":" # SStr
    end

    fun {IntToString N}
        {FloatToInt N}
    end

end
