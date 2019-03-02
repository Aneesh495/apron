# Constraint-Directed Runway Sequencing & Computation Spaces Specification

This document details the mathematical formulation, constraint propagators, and Oz computation space architecture used in Apron to solve the Departure Manager (DMAN) and Arrival Manager (AMAN) runway scheduling problems.

## 1. Problem Formulation

Runway sequencing is a combinatorial optimization problem belonging to the class of Job-Shop Scheduling with Sequence-Dependent Setup Times (JSS-SDST) and Asymmetric Traveling Salesperson with Time Windows (ATSP-TW), both known to be NP-hard.

Given:
- A set of flights $\mathcal{F} = \{f_1, f_2, \dots, f_N\}$
- For each departure $f_i$, an earliest runway arrival time $E_i = TOBT_i + EXOT_i$
- A latest runway departure time $L_i = E_i + \Delta_{max}$ (to satisfy slot compliance or crew duty limits)
- A set of operational runways $\mathcal{R} = \{r_1, r_2, \dots, r_M\}$
- A sequence-dependent setup time matrix $S(i, j, r)$ representing required wake turbulence separation and SID route divergence between consecutive aircraft $f_i$ and $f_j$ on runway $r$

### 1.1 Decision Variables
1. **Departure Time**: For each flight $f_i$, continuous variable $t_i \in [E_i, L_i]$
2. **Runway Assignment**: Discrete variable $r_i \in \mathcal{R}$
3. **Sequencing Precedence**: Binary variables $p_{ij} \in \{0, 1\}$ where $p_{ij} = 1$ if $f_i$ precedes $f_j$ on the same runway

### 1.2 Objective Function
Apron optimizes a weighted multi-criteria objective:
$$\min \mathcal{J} = \sum_{i=1}^N \left( \alpha_i \cdot \max(0, t_i - E_i) + \beta_i \cdot (t_i - E_i)^2 + \gamma_i \cdot Fuel(f_i, t_i - E_i) \right)$$

where:
- $\alpha_i$ penalizes linear schedule delay
- $\beta_i$ penalizes extreme delay variance (ensuring equity across airlines)
- $\gamma_i$ models auxiliary power unit (APU) and ground idling fuel burn

### 1.3 Hard Constraints
1. **Time Window Feasibility**:
   $$\forall i \in \{1, \dots, N\}: \quad E_i \le t_i \le L_i$$
2. **Wake and Route Spacing**:
   $$\forall i, j \text{ with } r_i = r_j \text{ and } p_{ij} = 1: \quad t_j \ge t_i + S(f_i, f_j, r_i)$$
3. **Interleaved Arrival/Departure Windows**:
   When runway $r$ operates in mixed mode with fixed arrival slots $A_k$:
   $$t_i \notin [A_k - \delta_{buf}, A_k + ROT_k + \delta_{wake}]$$
   where $ROT_k$ is the runway occupancy time of landing aircraft $k$.

## 2. Oz Computation Spaces for Branch-and-Bound Search

Oz provides first-class *computation spaces*, an abstraction that encapsulates constraint propagation, relational choice points, and speculative search.

```
       +---------------------------------------------+
       |             Root Computation Space          |
       |  - Store: Variables, Domains, Propagators   |
       |  - Status: alternatives(2)                  |
       +---------------------------------------------+
                        /             \
             {Space.clone}           {Space.clone}
                      /                 \
       +-----------------------+   +-----------------------+
       |   Branch 1 (p_ij = 1) |   |   Branch 2 (p_ji = 1) |
       |   f_i precedes f_j    |   |   f_j precedes f_i    |
       +-----------------------+   +-----------------------+
                  |                            |
            Propagate()                  Propagate()
                  |                            |
       Solution Cost C_1            Pruned (Infeasible/High Cost)
                  |
        Post Constraint:
        Cost <: C_1
```

### 2.1 Space Operations
- `Space.new(P, S)`: Allocates an isolated computation space $S$ and executes procedure $P$ inside it.
- `Space.ask(S, Status)`: Evaluates constraint propagation inside $S$ to a quiescent fixed point and returns:
  * `failed`: Inconsistency detected; domain is empty.
  * `succeeded`: All variables determined; valid schedule found.
  * `alternatives(N)`: Quiescence reached with $N$ unresolved choice points.
- `Space.clone(S, S_copy)`: Performs an $O(1)$ copy-on-write snapshot of space $S$.
- `Space.commit(S, Choice)`: Directs the speculative execution down branch `Choice`.

### 2.2 Branch-and-Bound Engine
```oz
fun {BranchAndBound BestSolution Space}
   case {Space.ask Space}
   of failed then
      BestSolution
   [] succeeded then
      NewCost = {Space.merge Space}.cost
      % Prune subsequent branches by posting tighter cost bound
      NewSpace = {Space.clone Space}
      {NewSpace.post Cost <: NewCost}
      {BranchAndBound NewCost NewSpace}
   [] alternatives(N) then
      % Speculatively explore choices via depth-first or best-first search
      LeftChild = {Space.clone Space}
      RightChild = {Space.clone Space}
      {Space.commit LeftChild 1}
      {Space.commit RightChild 2}
      ...
   end
end
```

## 3. Search Heuristics

1. **Variable Ordering: First-Fail Principle**:
   Branch on the flight pair $(f_i, f_j)$ with the smallest overlapping time window intersection:
   $$\Omega_{ij} = [ \max(E_i, E_j), \min(L_i, L_j) ]$$
   This quickly exposes infeasible subtrees near the root.

2. **Value Ordering: Wake-Compatible Clustering**:
   When deciding between $f_i \prec f_j$ versus $f_j \prec f_i$, prioritize placing aircraft of similar wake vortex categories consecutively (e.g., Heavy followed by Heavy instead of Heavy followed by Light). This minimizes total setup time on the runway.
