# Airport Collaborative Decision Making (A-CDM) Technical Specification

This document specifies the Airport Collaborative Decision Making (A-CDM) architecture implemented in Apron, conforming to Eurocontrol A-CDM Community specifications and ICAO Doc 9829 (Manual on Airport Collaborative Decision Making).

## 1. Executive Summary

A-CDM establishes transparent, deterministic data interchange between airport operators, aircraft operators (airlines), ground handling agents, Air Traffic Control (ATC), and the Network Manager Operations Centre (NMOC / Eurocontrol CFMU). The objective is to convert volatile departure estimates into predictable off-block and take-off milestones, minimizing surface congestion, engine idling, fuel burn, and gate contention.

In Apron, A-CDM is implemented as a concurrent, event-driven reactive network in Oz. Flight milestones are represented as concurrent dataflow streams where downstream times synchronize deterministically on upstream single-assignment bindings.

## 2. The 16 Turnaround Milestones

The life cycle of an aircraft turnaround is structured into 16 discrete operational milestones:

| Index | Milestone Name | Code | Trigger Event | Stakeholder Owner |
|---|---|---|---|---|
| M1 | Inbound Flight Plan Activated | IFPA | Radar tracking or NMOC flight plan activation | ATC / Network Manager |
| M2 | Inbound En-Route FIR Entry | FIR_ENTRY | Flight crosses Terminal Maneuvering Area (TMA) boundary | Radar / TMA ATC |
| M3 | Inbound Landing | ALDT | Wheels touch runway (touchdown) | Tower ATC / Surface Radar |
| M4 | Inbound In-Block | AIBT | Aircraft parked, chocks on at stand | Ground Handler / Apron Radar |
| M5 | Turnaround Service Commenced | SERV_COMM | Ground handling equipment positioned, doors open | Ground Handler |
| M6 | Target Off-Block Time Published | TOBT_PUB | Initial TOBT calculated based on turnaround schedule | Airline / Ground Handler |
| M7 | Turnaround Progress Check 1 | CHK_40 | TOBT - 40 min checkpoint (cleaning/fueling status) | Ground Handler |
| M8 | Turnaround Progress Check 2 | CHK_20 | TOBT - 20 min checkpoint (catering/baggage loading) | Ground Handler |
| M9 | Boarding Commenced | BRD_COMM | Gate boarding scanner opened, passengers boarding | Airline Gate Agent |
| M10 | TSAT Issued | TSAT_ISS | CDM sequencer computes optimal startup approval time | Apron / ATC Sequencer |
| M11 | Boarding Completed | BRD_COMP | All passengers onboard, cabin doors closed, jetbridge retracted | Airline / Flight Crew |
| M12 | Startup Request | ARD | Flight crew requests pushback and startup clearance | Flight Crew |
| M13 | Startup Approved | ASAT | Apron control grants pushback clearance | Apron Control |
| M14 | Actual Off-Block | AOBT | Aircraft moves from stand under tow or own power | Surface Radar / Apron |
| M15 | Taxi-Out Commenced | TAXI_OUT | Aircraft enters active taxiway network | Ground Control |
| M16 | Actual Take-Off | ATOT | Aircraft initiates runway departure roll | Tower ATC |

## 3. Milestone Mathematical Formulations

### 3.1 Estimated Taxi-In Time (EXIT) and In-Block Time (AIBT)
Given an assigned arrival runway $R_{arr}$ and assigned parking stand $S_{arr}$:
$$AIBT = ALDT + EXIT(R_{arr}, S_{arr})$$
where $EXIT(R_{arr}, S_{arr})$ is derived from the topological taxiway network traversal time, taking into account runway exit velocity, taxiway speed limits, and average crossing delays at intermediate holding positions.

### 3.2 Target Off-Block Time (TOBT)
The airline or ground handling agent determines TOBT based on minimum turnaround time ($MTTT$) and sub-process critical paths:
$$TOBT \ge AIBT + MTTT(Type_{ac}, Subservice)$$
where $Type_{ac}$ denotes the ICAO aircraft category (e.g., Code C narrowbody vs. Code E/F widebody). When sub-processes (fueling, catering, cleaning, boarding) encounter deviations:
$$TOBT_{revised} = \max(TOBT_{previous}, \max_{p \in Processes} (T_{start}(p) + D(p)))$$

### 3.3 Target Startup Approval Time (TSAT)
TSAT is calculated by the departure manager (DMAN) constraint solver:
$$TSAT = TTOT - EXOT(S_{dep}, R_{dep})$$
subject to:
$$TSAT \ge TOBT$$
$$TSAT \in [TOBT, TOBT + \Delta_{max\_window}]$$
where $EXOT(S_{dep}, R_{dep})$ is the variable estimated taxi-out time from stand $S_{dep}$ to departure runway $R_{dep}$, and $\Delta_{max\_window}$ is the maximum permissible holding delay at the stand before pushback (typically 15 to 20 minutes to prevent stand starvation).

### 3.4 Target Take-Off Time (TTOT)
TTOT represents the sequenced departure slot on the runway:
$$TTOT_k \ge TTOT_{k-1} + Sep(Type_{k-1}, Type_k, SID_{k-1}, SID_k)$$
where $Sep$ represents the required wake vortex separation plus Standard Instrument Departure (SID) route divergence buffers.

## 4. Departure Planning Information (DPI) Message Protocol

A-CDM generates standard telex/XML DPI messages to transmit operational intent to Eurocontrol NMOC:

### 4.1 Early DPI (E-DPI)
Emitted at $EOBT - 3\text{h}$ or upon inbound aircraft departure from upstream origin. Establishes the expected airframe link between inbound flight and outbound flight.

### 4.2 Target DPI (T-DPI)
Emitted whenever a reliable TOBT is established or modified by more than 5 minutes. Communicates:
- Flight Identifier (Callsign, GUFI)
- Departure Airport (ICAO code)
- Destination Airport (ICAO code)
- TOBT (UTC timestamp)
- EXOT (Estimated taxi-out minutes)
- Assigned parking stand

### 4.3 ATC Pre-DPI (A-DPI)
Emitted when the departure enters the sequencer freeze horizon (typically $TOBT - 30\text{ min}$). Communicates initial TSAT and tentative TTOT.

### 4.4 Sequenced Informative DPI (SIR-DPI)
Emitted after TSAT is confirmed and sequencing lock is applied. Any shift in runway configuration or surface flow immediately triggers a revised SIR-DPI.

### 4.5 Cancel DPI (C-DPI)
Emitted when an outbound flight is cancelled, suspended, or returns to stand after pushback.

## 5. Aircraft De-Icing Subsystem

During winter operations, aircraft undergo de-icing / anti-icing either at the stand or at centralized de-icing pads near runway holding points.

### 5.1 Holdover Time (HOT)
Anti-icing fluids (SAE Type II and Type IV) form a protective chemical barrier preventing frozen deposits from adhering to aerodynamic surfaces. Holdover Time $HOT$ is a function of:
- Fluid specification (Type I de-icing, Type II/IV anti-icing, dilution ratio)
- Ambient surface temperature $T_{amb}$
- Weather precipitation category (frost, freezing fog, light snow, moderate snow, freezing rain)

The fundamental safety constraint is:
$$TTOT \le T_{deice\_complete} + HOT(Fluid, Weather, T_{amb})$$
If $TTOT$ exceeds this upper bound, the anti-icing protection expires, requiring the aircraft to return for full secondary de-icing.

## 6. Oz Concurrent Implementation Model

In Apron, each flight turnaround is managed by an independent concurrent Oz thread that evaluates milestone transitions via logic streams:

```oz
functor
import
   Time
export
   TurnaroundManager
define
   proc {TurnaroundManager Flight InboundStream OutboundStream}
      % Concurrent dataflow variables synchronize automatically
      AIBT = {AwaitMilestone InboundStream m4_inblock}
      TOBT = {ComputeInitialTOBT Flight AIBT}
      TSAT = {RequestSequencerSlot Flight TOBT}
      TTOT = {DeriveTakeOffTime TSAT Flight}
      
      % Asynchronous dispatch of DPI messages
      thread {EmitDPI target_dpi Flight TOBT TSAT} end
      
      % Monitor pushback clearance
      {AwaitPushbackAuthorization Flight TSAT}
   end
end
```

By decoupling state transitions into single-assignment logic variables, Apron eliminates polling loops and guarantees deterministic event processing across thousands of concurrent flights.
