# apron

```
========================================================================================
   APRON: Airport Surface Movement & Collaborative Decision Making Engine
   A-SMGCS Level 4 Guidance | RECAT-EU Wake Sequencing | Oz Concurrent Core
========================================================================================
```

`apron` is a distributed, constraint-directed airport surface movement guidance, collaborative decision making (A-CDM), and runway sequencing engine. Built around the multi-paradigm concurrent logic programming language Oz, `apron` unifies declarative dataflow concurrency, first-class computation spaces, and rational tree unification to solve real-time aerodrome scheduling, 4D space-time taxiway routing, and wake turbulence separation problems at high-density multi-runway hubs.

The system integrates an embedded C11 Oz Virtual Machine (`ozvm`), hardware-accelerated WGS-84 geodesy and spatial R-tree fastpaths, zero-allocation Eurocontrol ASTERIX Category 011 and Category 012 surveillance stream decoders, and an autonomous multi-agent operational network modeling Tower ATC, Apron Ground Control, Cockpit Crews, and Ground Handling Equipment.

---

## Architecture Overview

```
                                      +---------------------------------------------+
                                      |          Eurocontrol ASTERIX Streams        |
                                      |   (Cat 011 Surveillance / Cat 012 Alerts)   |
                                      +----------------------+----------------------+
                                                             |
                                                             v
+-----------------------------+               +--------------+--------------+
|   IATA AIDX Flight Feeds    |               |    Zero-Allocation C11      |
|  (A-CDM Milestones, SOBT)   +-------------->|      ASTERIX Decoder        |
+--------------+--------------+               +--------------+--------------+
               |                                             |
               v                                             v
+--------------+---------------------------------------------+--------------+
|                                                                           |
|                       Embedded C11 Oz Virtual Machine                     |
|                                                                           |
|   +-----------------------+  +-----------------------+  +-------------+   |
|   | Single-Assignment     |  | Rational Tree         |  | Dataflow    |   |
|   | Store & Logic Vars    |  | Unification Engine    |  | Scheduler   |   |
|   +-----------+-----------+  +-----------+-----------+  +------+------+   |
|               |                          |                     |          |
|               v                          v                     v          |
|   +-------------------------------------------------------------------+   |
|   |              First-Class Computation Spaces (Search)              |   |
|   +----------------------------------+--------------------------------+   |
+--------------------------------------|------------------------------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
                   v                                       v
+------------------+------------------+ +------------------+------------------+
|    Runway Sequencing Subsystem      | |    4D Space-Time Routing Engine     |
|                                     | |                                     |
|  * RECAT-EU 6-Cat Wake Separation   | |  * Time-Expanded Reservation Graph  |
|  * SID Route Divergence Minima      | |  * Dynamic Moving Conflict Cones    |
|  * Branch-and-Bound Space Search    | |  * Pushback Cul-de-Sac Deconfliction|
|  * Mixed-Mode Interleaved Sched     | |  * Runway Crossing Hold Protocols   |
+------------------+------------------+ +------------------+------------------+
                   |                                       |
                   +-------------------+-------------------+
                                       |
                                       v
+--------------------------------------+------------------------------------+
|                  Autonomous Multi-Agent Actor Swarm                       |
|                                                                           |
|   +------------------+  +------------------+  +-----------------------+   |
|   | Tower Airfield   |  | Apron Ground     |  | Stand Allocation &    |   |
|   | Controller Agent |  | Controller Agent |  | Gate Management Agent |   |
|   +--------+---------+  +--------+---------+  +-----------+-----------+   |
|            |                     |                        |               |
|            v                     v                        v               |
|   +------------------+  +------------------+  +-----------------------+   |
|   | Cockpit Flight   |  | Pushback Tug &   |  | RIMCAS Runway Safety  |   |
|   | Crew Agent       |  | GSE Agent        |  | Incursion Monitor     |   |
|   +------------------+  +------------------+  +-----------------------+   |
+--------------------------------------+------------------------------------+
                                       |
                                       v
+--------------------------------------+------------------------------------+
|                Environmental & Operational Analytics                      |
|   * ICAO Doc 9883 Engine Idle Fuel Burn & Gate-Hold CO2 Conservation      |
|   * D0 / D15 / A14 Punctuality & Target Startup Approval Time Compliance  |
|   * Movements Per Hour & Hourly Capacity Saturation Rate                  |
+---------------------------------------------------------------------------+
```

---

## Core Capabilities

### 1. Constraint-Directed Runway Scheduling (DMAN / AMAN)
Traditional airport surface schedulers rely on greedy First-Come-First-Served (FCFS) heuristics that suffer from severe schedule instability and unnecessary wake turbulence delays during peak departure banks. `apron` formulates runway sequencing as a constrained optimization problem solved inside first-class Oz computation spaces.

- **RECAT-EU Wake Turbulence Categorization**: Implements pairwise matrix separation standards across six wake turbulence categories (Super, Upper Heavy, Lower Heavy, Upper Medium, Lower Medium, Light).
- **Standard Instrument Departure (SID) Route Divergence**: Applies procedural radar divergence intervals based on initial departure track divergence angles (same SID track: 120s; initial fix divergence >= 15 deg: 90s; >= 30 deg: 60s).
- **Mixed-Mode Operations**: Interleaves arrivals and departures on shared runways by computing arrival threshold flyover windows and inserting departure rolls within dynamic gaps.
- **Branch-and-Bound Search**: Explores alternative runway allocations, minimizing total system delay and schedule variance with monotonic cost distribution pruning:

$$\min \sum_{i \in \text{Flights}} \left( t_i^{\text{takeoff}} - t_i^{\text{ready}} \right) + \lambda \sum_{i \in \text{Flights}} \max(0, t_i^{\text{takeoff}} - \text{CTOT}_i)$$

Subject to:
$$t_j^{\text{takeoff}} - t_i^{\text{takeoff}} \ge S(W_i, W_j, \text{SID}_i, \text{SID}_j) \quad \forall (i, j) \in \text{Sequence}$$

### 2. 4D Space-Time Conflict-Free Taxiway Routing
Taxiway gridlock and pushback deadlocks represent the single largest source of apron delay. `apron` models the aerodrome movement network as a directed space-time graph:

$$\mathcal{G} = (\mathcal{V} \times \mathcal{T}, \mathcal{E})$$

- **Time-Expanded Reservation Intervals**: Each taxiway segment and node is reserved as a continuous time interval $[t_{\text{entry}} - \Delta t_{\text{buffer}}, t_{\text{exit}} + \Delta t_{\text{buffer}}]$. Two flights $A$ and $B$ traversing segment $e$ are conflict-free if and only if their intervals are disjoint:

$$\left[t_{e, A}^{\text{in}}, t_{e, A}^{\text{out}}\right] \cap \left[t_{e, B}^{\text{in}}, t_{e, B}^{\text{out}}\right] = \emptyset$$

- **Cul-de-Sac Pushback Blocking**: Dynamically reserves apron taxilanes during pushback maneuvers, holding adjacent stands until the aircraft has decoupled from the tow tug and engaged nose-wheel steering.
- **Runway Crossing Incursion Protection**: Enforces positive clearance reservations across active runway thresholds, checking radar line-of-sight and arrival deceleration profiles before clearing surface crossings.
- **Dynamic Jam Rerouting**: When sensor feeds report a stalled tug or taxiway obstruction, the engine dynamically recalculates the remaining 4D path without invalidating unrelated downstream reservations.

### 3. Comprehensive Airport Collaborative Decision Making (A-CDM)
Full implementation of the 16 standard Eurocontrol / ICAO turnaround milestones:

| Milestone | Code | Description | Trigger Entity |
|:---|:---|:---|:---|
| **01** | `FPL` | Flight Plan Activated | Network Manager (CFMU) |
| **02** | `EOBT` | Estimated Off-Block Time Established | Aircraft Operator (AO) |
| **03** | `ELDT` | Estimated Landing Time (TMA Radar Entry) | ATC Approach / AMAN |
| **04** | `ALDT` | Actual Landing Time (Runway Touchdown) | Tower ATC / Radar Cat 011 |
| **05** | `AIBT` | Actual In-Block Time (Chocks On at Stand) | Stand Sensor / Ground Handler |
| **06** | `SOBT` | Scheduled Off-Block Time Published | Airline Master Schedule |
| **07** | `TOBT_DEF` | Target Off-Block Time Initialized | Ground Handler / Airline |
| **08** | `TOBT_CONF` | Target Off-Block Time Confirmed | Cockpit Crew / Handling Agent |
| **09** | `TSAT_GEN` | Target Startup Approval Time Calculated | DMAN Sequencing Engine |
| **10** | `TOBT_RDY` | Readiness Confirmed (Boarding Complete) | Flight Crew / Ground Crew |
| **11** | `ASAT` | Actual Startup Approval Issued | Apron Ground ATC |
| **12** | `AOBT` | Actual Off-Block Time (Pushback Roll) | Ground Radar / Tow Tug Agent |
| **13** | `EXOT` | Estimated Taxi-Out Time Calculated | Aerodrome Routing Engine |
| **14** | `TTOT` | Target Take-Off Time Sequenced | Master Airfield Supervisor |
| **15** | `ASRT` | Actual Startup Roll Initiated | Cockpit Flight Crew |
| **16** | `ATOT` | Actual Take-Off Time (Wheels Off Ground) | Tower Radar Cat 011 |

### 4. Zero-Allocation Fastpath & Embedded C11 Oz Virtual Machine
To guarantee deterministic execution and sub-millisecond response times under peak surveillance loads, performance-critical modules are implemented in C11:

- **Single-Assignment Store**: Lock-free logic variable store with constant-time unbound allocation and path-compressed dereferencing.
- **Rational Tree Unification**: Unifies cyclic and acyclic records with visited-set cycle detection in $O(N \alpha(N))$ time.
- **Dataflow Thread Scheduler**: Preemptive, cooperative round-robin scheduler with event-driven thread waking triggered by store variable binding events.
- **Spatial R-Tree**: 2D R-tree index with quadratic node splitting for fast spatial lookups of moving radar targets ($> 1,000,000$ spatial queries per second).
- **WGS-84 Geodesy**: Direct spherical and local tangent plane (East-North-Up) projections without external GIS dependencies.
- **Eurocontrol ASTERIX Cat 011 / 012**: Ingests binary surveillance records directly into structured frame representations without intermediate heap allocations.

### 5. Environmental Fuel & Emissions Assessment
Calculates taxi fuel conservation in accordance with ICAO Doc 9883 (*Manual on Computing Emissions from Aircraft Surface Movement*):

- **Engine Idle Fuel Flow**: Calibrated flow rates for twin-aisle and single-aisle types (B77W: $0.56\text{ kg/s}$; A388: $1.12\text{ kg/s}$; A320: $0.15\text{ kg/s}$).
- **Virtual Queue Engine-Off Holds**: By metering aircraft at the gate during TSAT delays instead of releasing them into idling taxiway queues, the engine avoids $3.16\text{ kg CO}_2$ per kilogram of Jet-A1 fuel saved:

$$\Delta \text{CO}_2 = 3.16 \times \left( \dot{m}_{\text{idle}} - \dot{m}_{\text{APU}} \right) \cdot \Delta t_{\text{gate\_hold}}$$

---

## Directory Organization

```
apron/
|-- CMakeLists.txt              # Unified C11 build configuration with strict pedantic flags
|-- Makefile                    # Top-level build and test automation targets
|-- run_tests.sh                # End-to-end verification harness and em dash auditor
|-- docs/                       # Formal system specifications and architecture designs
|   |-- a_cdm_specification.md  # Eurocontrol A-CDM milestone state machines
|   |-- wake_turbulence_rules.md# RECAT-EU & ICAO wake separation matrices
|   |-- runway_scheduling.md    # Constraint programming computation spaces
|   |-- space_time_routing.md   # 4D time-expanded reservation network model
|   |-- asterix_protocols.md    # Eurocontrol Cat 011 & Cat 012 wire specifications
|   +-- oz_vm_architecture.md   # Single-assignment store and thread scheduler
|-- include/                    # Public C11 headers
|   |-- oz_store.h              # Store values, variables, and memory pools
|   |-- oz_space.h              # First-class computation spaces and choice points
|   |-- oz_vm.h                 # VM execution state and instruction bytecodes
|   |-- fastpath_geo.h          # WGS-84 geodesy and geofencing calculations
|   |-- fastpath_rtree.h        # 2D R-tree spatial index
|   +-- fastpath_asterix.h      # Zero-allocation Asterix frame decoder
|-- src/
|   |-- main.c                  # Unified apron command-line tool
|   |-- vm/                     # C11 Oz Virtual Machine implementation
|   |   |-- oz_store.c          # Single-assignment store and value allocators
|   |   |-- oz_unify.c          # Rational tree unification with cycle handling
|   |   |-- oz_scheduler.c      # Multi-threaded cooperative dataflow scheduler
|   |   |-- oz_space.c          # Computation space cloning, asking, and committing
|   |   |-- oz_lexer.c          # Oz token scanner
|   |   |-- oz_parser.c         # Recursive descent parser and AST builder
|   |   |-- oz_compiler.c       # Bytecode generator and instruction emitter
|   |   +-- oz_builtins.c       # Core built-in functions
|   |-- fastpath/               # Performance-critical C11 algorithms
|   |   |-- geo.c               # Haversine, forward bearing, and tangent plane projections
|   |   |-- rtree.c             # Quadratic split R-tree implementation
|   |   +-- asterix.c           # Binary Asterix Category 011 parser
|   +-- oz/                     # Core Oz Logic System
|       |-- prelude/            # Standard list combinators, folds, and math
|       |-- aerodrome/          # Airfield topology, runways, taxiways, and stands
|       |   |-- egll_layout.oz  # London Heathrow layout definition
|       |   |-- eddf_layout.oz  # Frankfurt Main layout definition
|       |   +-- eham_layout.oz  # Amsterdam Schiphol layout definition
|       |-- cdm/                # A-CDM 16-milestone state machine and TOBT/TSAT engines
|       |-- sequencing/         # RECAT-EU wake separation and branch-and-bound solver
|       |-- routing/            # 4D space-time pathfinder and pushback deconfliction
|       |-- safety/             # RIMCAS runway incursion monitor and safety alerts
|       |-- agents/             # Autonomous active port agents (Tower, Ground, Crew, Tug)
|       |-- protocols/          # AIDX XML, FIXM 4D, Asterix Cat 011/012, and AFTN codecs
|       |-- simulation/         # Discrete-event engine, stochastic ROT, and weather
|       +-- analytics/          # ICAO Doc 9883 emissions, D0/D15 punctuality, and reports
|-- data/                       # Reference fixtures and test datasets
|   |-- airports/               # Real-world aerodrome topologies (EGLL, EDDF, EHAM)
|   |-- aidx/                   # Validated IATA AIDX XML manifests
|   +-- asterix/                # Binary Asterix Cat 011 streams and Cat 012 alerts
|-- tools/                      # Analytical and visualizer scripts
|   |-- airfield_visualizer.py  # Generates high-resolution SVG aerodrome diagrams
|   |-- synthetic_aidx_gen.py   # High-volume AIDX schedule generator
|   |-- asterix_generator.py    # Synthetic radar target frame generator
|   +-- run_benchmarks.py       # Comprehensive micro-benchmark suite
+-- test/                       # Comprehensive verification test suites
    |-- c/                      # C11 unit tests (Store, Unify, Space, VM, Geo, RTree)
    |-- oz/                     # Oz subsystem unit tests (A-CDM, Sequencing, Routing)
    +-- python/                 # End-to-end integration and scenario tests
```

---

## Getting Started

### Prerequisites
- Clang / GCC with C11 support (`-std=c11`)
- CMake >= 3.16
- Python >= 3.8
- POSIX make

### Building the Project
Clone the repository and compile using the top-level Makefile:

```bash
git clone https://github.com/Aneesh495/apron.git
cd apron
make
```

This compiles:
1. `build/apron`: The unified operational command-line utility.
2. `build/ozvm`: The standalone Oz bytecode interpreter.
3. `build/libfastpath.a`: Hardware-accelerated geodesy, R-tree, and Asterix libraries.
4. `build/libozvm_lib.a`: The embedded Oz Virtual Machine library.

---

## Running the Verification Suite

Run the full end-to-end test and validation harness:

```bash
make test
```

This automatically runs:
1. **Em Dash Strictness Pass**: Scans all repository files to guarantee zero em dash violations.
2. **C11 CTest Suite**: Executes unit tests for the single-assignment store, unification engine, computation spaces, VM interpreter, WGS-84 geodesy, and R-tree index (6/6 tests passing).
3. **Oz Test Harness**: Validates functor structures, export interfaces, and pattern matching rules.
4. **Integration Test Suite**: Verifies CLI invocation, exit codes, and real-world airport layout JSON schemas.
5. **Multi-Runway Simulation Scenarios**: Simulates high-density peak departure banks and verifies wake vortex spacing constraints.
6. **Micro-Benchmark Suite**: Measures spatial geodesy and unification throughput.

To run micro-benchmarks individually:
```bash
make bench
```

Sample benchmark output:
```
[BENCHMARK] WGS-84 Geodesic Distance
  Iterations:     250,000
  Elapsed Time:   88.27 ms
  Throughput:     2,832,186 ops/sec

[BENCHMARK] C11 Fastpath & OzVM Test Suite
  Status:         PASSED
  Execution Time: 22.40 ms
```

---

## Command-Line Usage

The `apron` binary provides several subcommands for aerodrome simulation, runway scheduling, and surveillance processing:

```bash
# Display help and available subcommands
./build/apron --help

# Run stochastic surface simulation for an airport layout
./build/apron simulate --airport data/airports/egll_layout.json --duration 3600

# Compute constraint-directed runway sequence with RECAT-EU wake separation
./build/apron sequence --runway 27L --mode departure --manifest data/airports/egll_layout.json

# Calculate conflict-free 4D taxiway route from Stand 501 to Runway 27L
./build/apron route --from 501 --to 27L --layout data/airports/egll_layout.json

# Decode binary Eurocontrol Asterix Cat 011 radar target frames
./build/apron radar --input data/asterix/sample_cat011_stream.bin

# Inspect A-CDM turnaround milestone progress
./build/apron cdm --flight BAW142 --aidx data/aidx/sample_turnaround_egll.xml
```

---

## Visualizing Airfield Telemetry

To generate a scalable vector graphics (SVG) diagram of an airfield layout with active aircraft positions:

```bash
python3 tools/airfield_visualizer.py data/airports/egll_layout.json egll.svg
```

The resulting `egll.svg` renders all runways, centerlines, intermediate taxiway intersections, gate stands, and active surveillance targets.

---

## Reference Specifications
- **ICAO Doc 9883**: *Manual on Computing Emissions from Aircraft Surface Movement*
- **Eurocontrol A-CDM Implementation Manual**: *Airport Collaborative Decision Making*
- **Eurocontrol RECAT-EU**: *European Wake Turbulence Categorisation and Separation Minima*
- **Eurocontrol Standard ASTERIX Part 2b**: *Category 011 - Transmission of SMGCS Surveillance Data*
- **Eurocontrol Standard ASTERIX Part 2c**: *Category 012 - Transmission of SMGCS Safety Alerts*
- **IATA AIDX**: *Airport-Airline Data Exchange XML Standard, Schema 16.1*
- **ICAO Doc 9965**: *Manual on Flight Information Exchange Model (FIXM)*
- **Van Roy, P., & Haridi, S.**: *Concepts, Techniques, and Models of Computer Programming* (MIT Press, 2004)

---

## License
MIT License. Distributed and maintained as an open research and aerodrome systems engineering project.
