# Embedded Oz Virtual Machine & Execution Architecture Specification

This document details the architecture, memory model, single-assignment store, concurrency scheduler, and computation space primitives of the embedded Oz virtual machine implemented in Apron.

## 1. Overview of the Oz Execution Model

The Oz language, developed by Gert Smolka, Peter Van Roy, and Seif Haridi, unifies declarative programming, concurrent dataflow, message-passing concurrency, and constraint programming into a unified kernel calculus.

Apron embeds a high-performance C11 implementation of the Oz kernel virtual machine (`ozvm`), designed specifically for zero-overhead deterministic scheduling and low-latency constraint propagation.

```
+===================================================================================+
|                              OZ VIRTUAL MACHINE                                   |
+===================================================================================+
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                            SINGLE-ASSIGNMENT STORE                          |  |
|  |  [ Unbound Variables ] <---> [ Value Nodes ] <---> [ Equivalence Classes ]  |  |
|  +-----------------------------------------------------------------------------+  |
|                                       ^                                           |
|                                       | Dereference / Unify                       |
|                                       v                                           |
|  +-----------------------------------------------------------------------------+  |
|  |                        COOPERATIVE THREAD SCHEDULER                         |  |
|  |  - Active Run Queue (Round-Robin FIFO)                                      |  |
|  |  - Suspension Lists (Threads waiting on unbound variables)                  |  |
|  |  - Preemption Time-slice counter (Bytecode instruction budget)             |  |
|  +-----------------------------------------------------------------------------+  |
|                                       ^                                           |
|                                       | Space Isolation / Clone                   |
|                                       v                                           |
|  +-----------------------------------------------------------------------------+  |
|  |                         COMPUTATION SPACE MANAGER                           |  |
|  |  - Speculative Constraint Stores                                            |  |
|  |  - Trail / Undo Journal for Backtracking                                    |  |
|  |  - Status Evaluation: failed | succeeded | alternatives(N)                  |  |
|  +-----------------------------------------------------------------------------+  |
|                                       ^                                           |
|                                       | Register Windows / Dispatch                |
|                                       v                                           |
|  +-----------------------------------------------------------------------------+  |
|  |                         BYTECODE INTERPRETER LOOP                           |  |
|  |  - Direct Threaded Code or Switch-Case Dispatch                             |  |
|  |  - Register File (X0 - X255) per Thread Frame                               |  |
|  |  - High-Speed Record and List Pattern Matcher                               |  |
|  +-----------------------------------------------------------------------------+  |
+===================================================================================+
```

## 2. The Single-Assignment Store

In Oz, variables occupy one of three states:
1. **Unbound**: Created with no value. Threads attempting to observe the variable suspend.
2. **Equated (Aliased)**: Joined with another variable into an equivalence class via union-find with path compression.
3. **Determined (Bound)**: Associated permanently with a concrete value (integer, float, atom, record, tuple, or closure).

### 2.1 Rational Tree Unification
Unification of two values $V_1$ and $V_2$ proceeds recursively with cycle detection:
1. Dereference both $V_1$ and $V_2$ to find their canonical representatives in the store.
2. If both are the exact same variable node, succeed immediately ($O(1)$).
3. If one is unbound and the other is determined, bind the unbound variable, awaken all suspended threads waiting on it, and record the binding in the active space trail.
4. If both are unbound, union their equivalence classes.
5. If both are determined:
   - If primitive scalars (int, float, atom): succeed if equal, fail if unequal.
   - If records or tuples: succeed if labels match, arities match, and all corresponding feature fields recursively unify.

## 3. Concurrency and Dataflow Synchronization

### 3.1 Declarative Concurrency
In pure declarative concurrency, computations are concurrent yet deterministic. Concurrency is introduced via the `thread` keyword:

```oz
thread Result = {ExpensiveComputation X} end
{Consumer Result}
```

If `{Consumer Result}` accesses `Result` before `{ExpensiveComputation X}` finishes, the consumer thread automatically suspends on the unbound variable. No mutexes, condition variables, or semaphores are required.

### 3.2 Port Objects (Message Passing)
Asynchronous communication between concurrent entities (e.g., Apron Tower Controller and Aircraft Agents) is achieved using *Ports*:

```oz
local Stream Port in
   Port = {NewPort Stream}
   thread {ProcessMessages Stream} end
   {Send Port clearance_granted(flight: 101)}
end
```

`{NewPort Stream Port}` creates an atomic message queue where:
1. `Port` is a reference to the channel handle.
2. `Stream` is an unbound logic variable representing the head of the incoming message list.
3. Each `{Send Port M}` operation atomically binds the current tail of the stream to $M \mid \text{NewTail}$, where $\text{NewTail}$ is a fresh unbound variable.

## 4. Computation Space Primitives

A computation space encapsulates a constraint store and a set of speculative threads:

1. **`Space.new(Proc, SpaceRef)`**: Creates a nested child space.
2. **`Space.ask(SpaceRef, Status)`**: Runs all propagators inside the space until stability. If an inconsistency is reached, returns `failed`. If all variables are determined, returns `succeeded`. If unresolved choices remain, returns `alternatives(Count)`.
3. **`Space.clone(SpaceRef, CloneRef)`**: Clones the space by deep-copying modified store nodes while sharing immutable parent store pages.
4. **`Space.commit(SpaceRef, AlternativeIndex)`**: Posts the constraint corresponding to branch `AlternativeIndex`, narrowing the search space.

## 5. Bytecode Architecture

The virtual machine executes a compact register-based bytecode:

| Opcode | Mnemonic | Operands | Description |
|---|---|---|---|
| 0x01 | `OP_MOVE` | $r_d, r_s$ | Move register value |
| 0x02 | `OP_LOAD_INT` | $r_d, \text{imm32}$ | Load 32-bit signed integer |
| 0x03 | `OP_LOAD_ATOM` | $r_d, \text{atom\_id}$ | Load interned atom symbol |
| 0x04 | `OP_MAKE_UNBOUND`| $r_d$ | Allocate fresh unbound store variable |
| 0x05 | `OP_UNIFY` | $r_1, r_2$ | Unify contents of two registers |
| 0x06 | `OP_SUSPEND_IF` | $r_s$ | Suspend current thread if register is unbound |
| 0x07 | `OP_CALL` | $r_proc, \text{argc}$ | Invoke procedure closure |
| 0x08 | `OP_RETURN` | - | Return from current procedure frame |
| 0x09 | `OP_SPAWN` | $r_proc$ | Spawn concurrent dataflow thread |
| 0x0A | `OP_NEW_PORT` | $r_stream, r_port$| Create asynchronous port channel |
| 0x0B | `OP_SEND` | $r_port, r_msg$ | Send message through port |
| 0x0C | `OP_SPACE_NEW` | $r_proc, r_space$| Allocate child computation space |
| 0x0D | `OP_SPACE_ASK` | $r_space, r_stat$| Ask computation space status |
| 0x0E | `OP_SPACE_CLONE`| $r_space, r_copy$| Clone computation space |
| 0x0F | `OP_SPACE_COMMIT`| $r_space, \text{idx}$| Commit branch alternative |
