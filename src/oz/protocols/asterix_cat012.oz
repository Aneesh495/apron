% =============================================================================
% Apron Eurocontrol Asterix Cat 012 Alert Message Decoder
% Module: AsterixCat012
%
% Implements record decoding for Eurocontrol ASTERIX Category 012:
% Transmission of A-SMGCS Safety Alerts and RIMCAS Incursion Notifications.
% Decodes stage 1 advisories, stage 2 warnings, stage 3 emergency alarms,
% and stopbar crossing violation events.
% =============================================================================

functor
export
    DecodeCat012Record: DecodeCat012Record
    IsCriticalAlarm: IsCriticalAlarm
    FilterActiveAlerts: FilterActiveAlerts
define

    % Asterix Cat 012 Alert Record:
    % cat012Alert(sac: Int sic: Int
    %             alertId: Int
    %             alertType: Atom
    %             severity: Atom (advisory, warning, alarm)
    %             target1: Int
    %             target2: Int
    %             timeOfDay: Float
    %             active: Bool)

    fun {DecodeCat012Record RawFields}
        Sac = {CondSelect RawFields sac 25}
        Sic = {CondSelect RawFields sic 1}
        AlertId = {CondSelect RawFields alertId 0}
        Type = {CondSelect RawFields alertType 'RIMCAS_INC'}
        Severity = {CondSelect RawFields severity 'warning'}
        T1 = {CondSelect RawFields target1 0}
        T2 = {CondSelect RawFields target2 0}
        TimeSec = {CondSelect RawFields timeOfDay 0.0}
        Active = {CondSelect RawFields active true}
    in
        cat012Alert(sac: Sac
                    sic: Sic
                    alertId: AlertId
                    alertType: Type
                    severity: Severity
                    target1: T1
                    target2: T2
                    timeOfDay: TimeSec
                    active: Active)
    end

    fun {IsCriticalAlarm Alert}
        Alert.severity == 'alarm' andthen Alert.active
    end

    fun {FilterActiveAlerts Alerts}
        case Alerts
        of nil then nil
        [] A|Rest then
            if A.active then
                A|{FilterActiveAlerts Rest}
            else
                {FilterActiveAlerts Rest}
            end
        end
    end

end
