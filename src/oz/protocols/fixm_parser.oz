% =============================================================================
% Apron FIXM Trajectory Exchange Data Model & Parser
% Module: FIXMParser
%
% Implements data models and extractors for the Flight Information Exchange
% Model (FIXM v4.2+). Decodes 4D trajectory representations (4DT), en-route
% waypoints, aerodynamic profile predictions, departure and arrival aerodrome
% references, and wake turbulence classifications.
% =============================================================================

functor
export
    ParseFIXMTrajectory: ParseFIXMTrajectory
    GetTrajectoryWaypoint: GetTrajectoryWaypoint
    InterpolatePositionAtTime: InterpolatePositionAtTime
    CalculateTrajectoryLength: CalculateTrajectoryLength
define

    % FIXM 4D Trajectory Point:
    % trajectoryPoint(lat: Float lon: Float alt: Float time: Int speed: Float)

    % FIXM Flight Record:
    % fixmFlight(callsign: Callsign
    %            origin: Origin
    %            dest: Dest
    %            wakeCat: Cat
    %            points: ListOfPoints)

    fun {ParseFIXMTrajectory RawRecord}
        Callsign = {CondSelect RawRecord callsign "UNKNOWN"}
        Origin = {CondSelect RawRecord origin "EGLL"}
        Dest = {CondSelect RawRecord dest "KJFK"}
        WakeCat = {CondSelect RawRecord wakeCategory "H"}
        Points = {CondSelect RawRecord trajectoryPoints nil}
    in
        fixmFlight(callsign: Callsign
                   origin: Origin
                   dest: Dest
                   wakeCat: WakeCat
                   points: Points)
    end

    fun {GetTrajectoryWaypoint Trajectory Index}
        {ListNth Trajectory.points Index}
    end

    fun {ListNth List N}
        case List
        of nil then none
        [] H|T then
            if N == 1 then H
            else {ListNth T N - 1} end
        end
    end

    fun {InterpolatePositionAtTime Trajectory TargetTime}
        % Scans through trajectory points to find interval [P1, P2] containing TargetTime
        {FindInterval Trajectory.points TargetTime}
    end

    fun {FindInterval Points TargetTime}
        case Points
        of nil then none
        [] [P] then P
        [] P1|P2|Rest then
            if TargetTime >= P1.time andthen TargetTime =< P2.time then
                Duration = P2.time - P1.time
            in
                if Duration == 0 then P1
                else
                    Fraction = {IntToFloat (TargetTime - P1.time)} / {IntToFloat Duration}
                    InterpLat = P1.lat + Fraction * (P2.lat - P1.lat)
                    InterpLon = P1.lon + Fraction * (P2.lon - P1.lon)
                    InterpAlt = P1.alt + Fraction * (P2.alt - P1.alt)
                in
                    trajectoryPoint(lat: InterpLat
                                    lon: InterpLon
                                    alt: InterpAlt
                                    time: TargetTime
                                    speed: P1.speed)
                end
            else
                {FindInterval P2|Rest TargetTime}
            end
        end
    end

    fun {CalculateTrajectoryLength Points}
        case Points
        of nil then 0.0
        [] [_] then 0.0
        [] P1|P2|Rest then
            DLat = P2.lat - P1.lat
            DLon = P2.lon - P1.lon
            Dist = {Sqrt (DLat * DLat + DLon * DLon)} * 111139.0
        in
            Dist + {CalculateTrajectoryLength P2|Rest}
        end
    end

end
