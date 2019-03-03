# Space-Time Reservation Networks & Conflict-Free Taxiway Routing Specification

This document details the airfield graph representation, 4D space-time reservation structures, kinematic velocity models, and conflict resolution algorithms implemented in Apron.

## 1. Topological Airfield Graph

The movement area of an aerodrome is modeled as a directed, weighted planar multigraph:
$$\mathcal{G} = (\mathcal{V}, \mathcal{E})$$

### 1.1 Vertex Definitions ($\mathcal{V}$)
Each vertex $v \in \mathcal{V}$ corresponds to a physical surface feature:
- **Stands ($S$)**: Aircraft parking positions equipped with passenger boarding bridges or airstairs.
- **Pushback Release Points ($P$)**: Defined coordinates on taxiway centerlines where the aircraft is unhooked from the tow tug.
- **Intersections ($I$)**: Divergence, convergence, or crossing points of taxiway centerlines.
- **Intermediate Holding Positions ($H$)**: Marked holding lines where aircraft can hold short of conflicting traffic or apron boundaries.
- **Runway Holding Positions / CAT I/II/III Stopbars ($B$)**: Electrically switchable red stopbars and holding points guarding active runways.
- **Rapid Exit Taxiways ($RET$)**: High-speed exits designed to allow landing aircraft to vacate runways at speeds up to 50 knots (93 km/h).
- **Runway Thresholds ($R$)**: Designated entry points for take-off roll.

### 1.2 Edge Definitions ($\mathcal{E}$)
Each directed edge $e = (u, v) \in \mathcal{E}$ represents a taxiway centerline segment with physical and operational attributes:
- Length: $L(e) \in \mathbb{R}^+$ (meters)
- Maximum Speed Limit: $v_{max}(e) \in \mathbb{R}^+$ (typically 15 to 30 knots on straight taxiways, 8 to 12 knots on apron taxi-lanes, 10 to 15 knots on turns)
- Wingspan Restriction: $W_{max}(e) \in \mathbb{R}^+$ (ICAO Code A through F)
- Directionality: Bidirectional, unidirectional, or operationally switchable
- Turn Curvature Radius: $R_{curve}(e) \in \mathbb{R}^+$

## 2. The 4D Space-Time Reservation Table

To guarantee conflict-free surface movement without stop-and-go stutter, Apron employs a time-expanded reservation table $\mathcal{T}$:

$$\mathcal{T}: (\mathcal{E} \cup \mathcal{V}) \times \mathbb{R}^+ \to \mathcal{A} \cup \{\emptyset\}$$

where $\mathcal{A}$ is the set of active aircraft.

### 2.1 Reservation Windows
When aircraft $a_k$ traverses edge $e = (u, v)$ departing node $u$ at time $t_{dep}$ and arriving at node $v$ at time $t_{arr}$:
1. **Edge Reservation**:
   $$\forall \tau \in [t_{dep} - \delta_{buf}, t_{arr} + \delta_{buf}], \quad \mathcal{T}(e, \tau) \leftarrow a_k$$
   where $\delta_{buf}$ accounts for positioning uncertainty and reaction time.
2. **Reverse Edge Invalidation (Head-on Prevention)**:
   If edge $e' = (v, u)$ is the opposing direction of $e$:
   $$\forall \tau \in [t_{dep} - \delta_{buf}, t_{arr} + \delta_{buf}], \quad \mathcal{T}(e', \tau) \leftarrow a_k$$
3. **Node Clearance Reservation**:
   Node $v$ is reserved for the interval:
   $$[t_{arr} - \Delta t_{node}, t_{arr} + \Delta t_{node}]$$

## 3. Conflict Taxonomies and Detection Predicates

Apron monitors four distinct surface conflict patterns:

```
1. Head-on Conflict:
   [ Aircraft A ---> ] <==== (Single Lane Taxiway) ====> [ <--- Aircraft B ]

2. Tailgating (Catch-up) Conflict:
   [ Aircraft A (Slow) ---> ]  ....  [ Aircraft B (Fast) ---> ]
   Distance < D_safe(v_A, v_B)

3. Intersection Crossing Conflict:
                 |  Aircraft B (v)
                 v
   Aircraft A ---> [ Crossing Node ]
                 |

4. Jet Blast Hazard:
   [ Widebody (Takeoff Thrust) ] ======>> [ High Velocity Cone ] ======>> [ Light Aircraft ]
```

### 3.1 Minimum Safe Following Distance ($D_{safe}$)
For aircraft $B$ following aircraft $A$ at speed $v_B$:
$$D_{safe} = v_B \cdot \tau_{react} + \frac{v_B^2}{2 \cdot a_{decel}} + L_{aircraft} + D_{standoff}$$
where:
- $\tau_{react} = 2.0\text{ s}$ is pilot/tug reaction latency
- $a_{decel} = 1.5\text{ m/s}^2$ is nominal service braking deceleration
- $D_{standoff} = 15\text{ m}$ is safety buffer

### 3.2 Jet Blast Hazard Zones
Jet blast ground velocity decays with distance $x$ behind the engine exhaust nozzle:
$$U(x) = U_{exit} \cdot \left(\frac{d_{nozzle}}{x}\right) \cdot \exp\left(-\frac{r^2}{2 \sigma^2(x)}\right)$$
When a widebody (Code E/F) initiates breakaway thrust ($70\%\text{ to }80\%$ N1), trailing taxiway segments within 150 meters are temporarily marked hazardous in $\mathcal{T}$.

## 4. Space-Time Pathfinding Algorithm

Apron executes Space-Time $A^*$ routing over $\mathcal{G}$:

1. **State Space**: Each search state is represented by $(u, t)$, denoting arrival at node $u$ at timestamp $t$.
2. **Admissible Heuristic**:
   $$h(u, t) = \frac{\text{EuclideanDistance}(u, \text{Destination})}{v_{max\_airfield}}$$
3. **Transition Function**:
   From state $(u, t)$, candidate edges $e = (u, w) \in \mathcal{E}$ are valid if and only if:
   $$\forall \tau \in [t, t + \text{TransitTime}(e)], \quad \mathcal{T}(e, \tau) = \emptyset$$
   If an edge is temporarily blocked by another aircraft, wait states $(u, t + \Delta t_{wait})$ are explored up to a maximum hold threshold.
