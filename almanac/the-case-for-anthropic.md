# The Case for Anthropic's Orchestrator-Workers Pattern

The almanac's Stage 2 (Evaluation) requires an agentic system that, given a set of candidate events, evaluates each one by asking branching questions — whether a speaking slot is open, whether the deadline is compatible with the travel window, whether family can co-travel during school holidays, whether a loyalty-programme hotel is available near the venue — and aggregates the answers into scored options for the user to decide among. This document records why the Anthropic orchestrator-workers pattern (as implemented in the Claude Agent SDK) is preferred over LangGraph's StateGraph for this purpose.

## The two patterns

**LangGraph StateGraph.** The developer declares a graph in Python: nodes are functions or LLM calls, edges are transitions (unconditional or conditional on state), and state is a typed dictionary that accumulates as execution flows through the graph. Fan-out, fan-in, subgraphs, and human-in-the-loop interrupts are first-class primitives. The graph is defined at compile time; the runtime executes it.

**Anthropic orchestrator-workers.** A central agent (the orchestrator) receives a task and a set of tools, some of which are themselves agents (workers). The orchestrator reasons about what to do, calls tools as needed, reads results, and continues. There is no explicit graph; the orchestration emerges from the orchestrator's prompt and the tool definitions. Subagent delegation is a tool call; fan-out is multiple concurrent tool calls; human-in-the-loop is a tool that pauses for input.

## Why orchestrator-workers fits the almanac evaluation

### The decision logic is judgment, not routing

The evaluation questions are not boolean dispatches. "Is networking-only attendance worthwhile?" requires weighing the event's attendee list, the user's relationship-building goals, and the opportunity cost of the trip. "Should I submit a speaking proposal?" depends on topic fit, preparation time, and whether the conference's audience aligns with the user's professional interests. These are LLM reasoning tasks, not `if/else` branches.

In LangGraph, each such question becomes a node whose implementation is an LLM call, and the conditional edge leading to it is also decided by an LLM call (or by a thin wrapper that parses the previous node's output). The explicit graph structure adds a layer of Python code that duplicates what the orchestrator's prompt already expresses in natural language. The graph definition becomes a maintenance burden without a corresponding gain in control, because the actual decisions are made by the LLM inside the nodes, not by the edges between them.

### The graph shape varies per event

A meetup has no speaking-slot branch. A cultural event near the home base needs no accommodation feasibility check. A conference during school holidays triggers the companion question; one in October does not. In LangGraph, handling this requires many conditional edges, no-op pass-through nodes, or runtime graph modification. In the orchestrator pattern, the orchestrator simply does not call the irrelevant tool. Branches that do not apply are never entered rather than explicitly skipped.

### Subagent delegation maps naturally to tool calls

The accommodation feasibility check — querying whether an IHG Platinum or Marriott Gold property near the conference city has family suites available on the relevant dates — is a well-defined subtask with clear inputs and outputs. In the orchestrator pattern, it is a tool: `check_accommodation_feasibility(city, dates, loyalty_programs, party_size)`. The orchestrator calls it when it judges the check is relevant, reads the structured result, and incorporates it into the event score. No graph wiring is needed to connect this capability; it is available whenever the orchestrator needs it.

### The existing system already follows this pattern

The almanac's sweep agent (`sweep.md`) is a prompt executed via `claude -p`. The travel SOPs are prompts. The invocation model is already orchestrator-workers in informal form: a master prompt delegates to specialised prompts, each of which produces structured output consumed by the next stage. Adopting the Anthropic Agent SDK formalises this existing pattern — defining tools and worker agents explicitly — rather than replacing it with a fundamentally different execution model.

### Human-in-the-loop is the intended exit

The evaluation system does not make decisions. It presents scored options to the user, who makes presence decisions. This is a single interrupt point at the end of the evaluation, not a complex multi-step approval workflow. The orchestrator pattern handles this naturally: the orchestrator completes its evaluation, produces a summary, and returns it to the user. LangGraph's interrupt machinery (checkpointing, state serialisation, resumption) is designed for more complex human interaction patterns and would be underused here.

## Where LangGraph would be preferable

LangGraph's explicit graph is valuable when the routing is deterministic and the volume is high — ETL pipelines, customer support triage with well-defined categories, or compliance workflows where auditability of the exact execution path is required. It is also valuable when the graph shape is stable across invocations: the overhead of defining the graph in code is repaid by predictable, repeatable execution.

The almanac evaluation has none of these characteristics. The volume is low (tens of events, not thousands). The routing varies per event. The decisions are judgment calls. The user reviews the output regardless.

## Implementation direction

The evaluation stage would be implemented as:

1. An **orchestrator agent** whose prompt encodes the evaluation methodology — the questions to ask, the scoring logic, the output format.
2. **Worker tools** for tasks that require external data or specialised logic:
   - `check_speaking_opportunity(event)` — checks whether a CFP is open and whether the deadline is within the travel window.
   - `check_accommodation_feasibility(city, dates, loyalty_programs, party_size)` — queries hotel availability at loyalty properties.
   - `check_companion_viability(event, seasonal_presence)` — determines whether family co-travel is feasible given school holiday overlap and routing.
   - `score_cluster(events, base, travel_window)` — aggregates individual event evaluations into a cluster score.
3. A **structured output format** that the orchestrator produces: per-event evaluations with participation-mode recommendations (speaker / attendee / networking-only / skip), per-cluster scores, and a presence-decision proposal for the user to review.

The orchestrator's prompt, not a graph definition, encodes the decision tree. The tools, not graph nodes, provide the capabilities. The user, not the system, makes the final decision.
