% =============================================================================
% Apron Eurocontrol Asterix Cat 011 Record Stream Decoder
% Module: AsterixCat011
%
% Implements record unpacking and field extraction for Eurocontrol ASTERIX
% Category 011: Transmission of A-SMGCS Surface Movement Surveillance Data.
% Decodes surface multilateration (MLAT), surface movement radar (SMR), and
% ADS-B ground tracks into high-fidelity radar target records.
% =============================================================================

functor
export
    DecodeCat011Record: DecodeCat011Record
    FilterConfirmedTracks: FilterConfirmedTracks
    FilterRunwayAreaTracks: FilterRunwayAreaTracks
define

    % Asterix Cat 011 Target Record:
    % cat011Target(sac: Int sic: Int
    %              trackNumber: Int
    %              timeOfDay: Float
    %              x: Float y: Float
    %              vx: Float vy: Float
    %              modeA: Int
    %              callsign: Atom
    %              confirmed: Bool)

    fun {DecodeCat011Record RawFields}
        Sac = {CondSelect RawFields sac 25}
        Sic = {CondSelect RawFields sic 1}
        TrackNum = {CondSelect RawFields trackNumber 0}
        TimeSec = {CondSelect RawFields timeOfDay 0.0}
        XPos = {CondSelect RawFields x 0.0}
        YPos = {CondSelect RawFields y 0.0}
        Vx = {CondSelect RawFields vx 0.0}
        Vy = {CondSelect RawFields vy 0.0}
        ModeA = {CondSelect RawFields modeA 1000}
        Callsign = {CondSelect RawFields callsign 'UNKNOWN'}
        Confirmed = {CondSelect RawFields confirmed true}
    in
        cat011Target(sac: Sac
                     sic: Sic
                     trackNumber: TrackNum
                     timeOfDay: TimeSec
                     x: XPos
                     y: YPos
                     vx: Vx
                     vy: Vy
                     modeA: ModeA
                     callsign: Callsign
                     confirmed: Confirmed)
    end

    fun {FilterConfirmedTracks Records}
        case Records
        of nil then nil
        [] R|Rest then
            if R.confirmed then
                R|{FilterConfirmedTracks Rest}
            else
                {FilterConfirmedTracks Rest}
            end
        end
    end

    fun {FilterRunwayAreaTracks Records MinX MaxX MinY MaxY}
        case Records
        of nil then nil
        [] R|Rest then
            if R.x >= MinX andthen R.x =< MaxX andthen
               R.y >= MinY andthen R.y =< MaxY then
                R|{FilterRunwayAreaTracks Rest MinX MaxX MinY MaxY}
            else
                {FilterRunwayAreaTracks Rest MinX MaxX MinY MaxY}
            end
        end
    end

end
