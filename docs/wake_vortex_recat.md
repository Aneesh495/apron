# Wake Vortex Separation & RECAT-EU Technical Specification

This document details the aerodynamics, separation standards, and combinatorial matrices governing aircraft spacing in Apron, covering both standard ICAO classification and European Wake Vortex Re-categorization (RECAT-EU).

## 1. Physical Foundations of Wake Turbulence

Every aircraft in flight generates a pair of counter-rotating trailing vortices behind its wingtips as a consequence of lift generation. The initial vortex circulation strength $\Gamma_0$ is expressed by the Kutta-Joukowski theorem:

$$\Gamma_0 = \frac{M \cdot g}{\rho_\infty \cdot V_\infty \cdot b_0}$$

where:
- $M$ is the instantaneous aircraft mass (kg)
- $g$ is the acceleration due to gravity ($9.80665 \text{ m/s}^2$)
- $\rho_\infty$ is the ambient air density ($\text{kg/m}^3$)
- $V_\infty$ is the true airspeed ($\text{m/s}$)
- $b_0 = \frac{\pi}{4} b$ is the initial vortex core separation for an elliptical lift distribution with wingspan $b$

### 1.1 Vortex Kinematics and Atmospheric Decay
Trailing vortices descend behind the generating aircraft at a velocity:
$$w_0 = \frac{\Gamma_0}{2 \pi b_0}$$
typically descending at 300 to 500 feet per minute until reaching ground proximity (ground effect within one wingspan height), where vortices level off and drift laterally across parallel runways under ambient crosswind shear:
$$v_{lateral} = \pm w_0 + u_{crosswind}$$

Atmospheric dissipation occurs via two regimes:
1. Diffusion and turbulent eddy viscosity dissipation.
2. Crow instability: mutual inductive amplification of sinusoidal perturbations resulting in vortex ring reconnection and rapid energy collapse.

## 2. RECAT-EU 6-Category Classification

Traditional ICAO 3-tier classification (Heavy, Medium, Light) imposes excessively conservative buffers on modern aircraft fleets. RECAT-EU refines separation into six optimized categories based on maximum take-off weight ($MTOW$) and wingspan ($b$):

| Category | Descriptor | MTOW Range | Wingspan Range | Representative Aircraft |
|---|---|---|---|---|
| CAT-A | Super Heavy | $MTOW \ge 100\text{t}$ | $b \ge 72\text{ m}$ | Airbus A380-800, Antonov An-225 |
| CAT-B | Upper Heavy | $MTOW \ge 100\text{t}$ | $60\text{ m} \le b < 72\text{ m}$ | Boeing 777-200/300/300ER, 747-400/8, Airbus A350-900/1000 |
| CAT-C | Lower Heavy | $MTOW \ge 100\text{t}$ | $b < 60\text{ m}$ | Boeing 767-200/300/400, 787-8/9/10, Airbus A300, A310, A330 |
| CAT-D | Upper Medium | $15\text{t} < MTOW < 100\text{t}$ | $32\text{ m} \le b < 52\text{ m}$ | Boeing 757, 737 MAX 8/9/10, Airbus A320neo, A321neo |
| CAT-E | Lower Medium | $15\text{t} < MTOW < 100\text{t}$ | $b < 32\text{ m}$ | Embraer E190/E195, Airbus A220-100/300, ATR 42/72, Dash 8-Q400 |
| CAT-F | Light | $MTOW \le 15\text{t}$ | All wingspans | Cessna Citation, Beechcraft King Air, Piper PA-34, light GA |

## 3. Pairwise Separation Matrices

### 3.1 Approach Radar Separation Matrix (Nautical Miles)
On final approach glideslope, minimum distance spacing between leading aircraft (row) and trailing aircraft (column) is defined as follows:

| Leader \ Follower | CAT-A | CAT-B | CAT-C | CAT-D | CAT-E | CAT-F |
|---|---|---|---|---|---|---|
| **CAT-A** | 3.0 NM | 4.0 NM | 5.0 NM | 5.0 NM | 6.0 NM | 8.0 NM |
| **CAT-B** | 3.0 NM | 3.0 NM | 4.0 NM | 4.0 NM | 5.0 NM | 7.0 NM |
| **CAT-C** | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 4.0 NM | 6.0 NM |
| **CAT-D** | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 5.0 NM |
| **CAT-E** | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 4.0 NM |
| **CAT-F** | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM | 3.0 NM |

*Note: 3.0 NM represents minimum radar separation when wake turbulence is not the constraining factor.*

### 3.2 Departure Runway Roll Separation Matrix (Seconds)
Between successive departures from the same runway or closely spaced parallel runways:

| Leader \ Follower | CAT-A | CAT-B | CAT-C | CAT-D | CAT-E | CAT-F |
|---|---|---|---|---|---|---|
| **CAT-A** | 100 s | 120 s | 140 s | 160 s | 180 s | 200 s |
| **CAT-B** | 90 s  | 100 s | 120 s | 120 s | 140 s | 160 s |
| **CAT-C** | 80 s  | 80 s  | 90 s  | 100 s | 120 s | 140 s |
| **CAT-D** | 70 s  | 70 s  | 70 s  | 80 s  | 100 s | 120 s |
| **CAT-E** | 60 s  | 60 s  | 60 s  | 60 s  | 80 s  | 100 s |
| **CAT-F** | 60 s  | 60 s  | 60 s  | 60 s  | 60 s  | 80 s  |

## 4. Standard Instrument Departure (SID) Route Divergence Rules

Wake vortex separation establishes the safety lower bound, but route geometry imposes air traffic route separation:

1. **Identical or Convergent SIDs (Divergence $< 15^\circ$)**:
   $$\Delta t_{dep} = \max(\Delta t_{wake}, 120\text{ s})$$
2. **Adjacent SIDs with Minor Divergence ($15^\circ \le \Delta \theta < 45^\circ$)**:
   $$\Delta t_{dep} = \max(\Delta t_{wake}, 90\text{ s})$$
3. **Divergent SIDs ($\Delta \theta \ge 45^\circ$ immediately after departure)**:
   $$\Delta t_{dep} = \max(\Delta t_{wake}, 60\text{ s})$$

### 4.1 Reduced Runway Separation Minima (RRSM)
Under visual meteorological conditions (VMC) and dry runway surface conditions, a second departure roll may commence when:
- Preceding aircraft is airborne and has crossed the upwind runway threshold or traveled at least 2,400 meters down the runway.
- Any conflicting landing aircraft has vacated the active runway over an exit taxiway.

## 5. Constraint Propagation Formulation in Oz

Apron encodes wake vortex separation as finite-domain distance constraints over sequence variable pairs:

```oz
proc {EnforceWakeConstraint Leader Follower SepMatrix Space}
   LeadCat = Leader.recatCategory
   FollowCat = Follower.recatCategory
   MinSeparation = {GetMatrixEntry SepMatrix LeadCat FollowCat}
   
   % Finite domain constraint: Follower roll cannot start before Leader + MinSeparation
   Follower.takeOffTime >=: Leader.takeOffTime + MinSeparation
end
```

When solving mixed-mode runway schedules, this constraint propagator prunes illegal departure windows early in the branch-and-bound search tree.
