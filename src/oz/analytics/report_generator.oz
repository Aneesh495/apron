% =============================================================================
% Apron Airfield Performance Analytics Report Generator
% Module: ReportGenerator
%
% Synthesizes airfield simulation execution logs into executive markdown and
% text reports. Aggregates throughput metrics, punctuality percentages, total
% delay hours, fuel burn, and environmental CO2 emissions savings.
% =============================================================================

functor
export
    GenerateOperationalSummary: GenerateOperationalSummary
define

    fun {GenerateOperationalSummary Metrics}
        "# Apron Operational Performance Report\n\n" #
        "## 1. Flight Punctuality & Slot Compliance\n" #
        "- D0 Punctuality: " # {FloatToString Metrics.d0} # "%\n" #
        "- D15 Punctuality: " # {FloatToString Metrics.d15} # "%\n" #
        "- TSAT Window Compliance: " # {FloatToString Metrics.tsatCompliance} # "%\n" #
        "- ATFM Slot Compliance: " # {FloatToString Metrics.atfmCompliance} # "%\n\n" #
        "## 2. Airfield & Runway Throughput\n" #
        "- Total Operations: " # {IntToString Metrics.totalMovements} # "\n" #
        "- Mean Movements per Hour: " # {FloatToString Metrics.movementsPerHour} # "\n" #
        "- Peak Capacity Utilization: " # {FloatToString Metrics.capacityUtilization} # "%\n" #
        "- Average Departure Headway: " # {FloatToString Metrics.avgHeadway} # " s\n\n" #
        "## 3. Delays & Stand Utilization\n" #
        "- Total Delay: " # {IntToString Metrics.totalDelayMinutes} # " minutes\n" #
        "- Average Delay per Flight: " # {FloatToString Metrics.avgDelayMinutes} # " minutes\n" #
        "- Stand Occupancy Rate: " # {FloatToString Metrics.standOccupancy} # "%\n\n" #
        "## 4. Environmental Impact & Fuel Conservation\n" #
        "- Total Taxi Fuel Consumed: " # {FloatToString Metrics.fuelBurnKg} # " kg\n" #
        "- Engine-Off Gate Hold Fuel Saved: " # {FloatToString Metrics.fuelSavedKg} # " kg\n" #
        "- CO2 Emissions Avoided: " # {FloatToString Metrics.co2SavedKg} # " kg\n"
    end

    fun {FloatToString F}
        % Basic float string representation helper
        {IntToString {FloatToInt F}}
    end

    fun {IntToString N}
        {FloatToInt N}
    end

end
