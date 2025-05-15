# Lab 4 – Otter with Hazards
**Pipelined RV32I OTTER Processor with Hazard Support**

## Overview

This lab is a continuation of our Pipelined OTTER implementation from Lab 3. The goal is to implement a complete pipelined processor supporting the RV32I (limited) instruction set, with full hazard detection and resolution. Key features include:

- Branch support
- Jump support
- Forwarding
- Hazard detection
- Pipeline stalls and flushes
- Branch prediction

In Lab 3, we pipelined the load/store and R/I-type instructions. We also combined the FSM and decoder into a unified **Control Unit (CU)** module.

## Objectives

- Extend the pipelined OTTER processor to support:
  - Branch instructions (BEQ, BNE, etc.)
  - Jump instructions (JAL, JALR)
  - Branch prediction
  - Forwarding logic to avoid data hazards
  - Hazard detection unit
  - Pipeline stalls and flushes

---

## Background Reading / Research TODO

Before beginning implementation, complete the following:

- [ ] Understand all **types of hazards**:
  - **Data Hazards**: RAW (Read After Write), WAR (Write After Read), WAW (Write After Write)
  - **Control Hazards**: From branches and jumps
  - **Structural Hazards**: If shared resources cause conflicts (less relevant for a well-designed pipeline)
- [ ] Study **how to resolve hazards**:
  - **Forwarding** (bypass paths)
  - **Stalling** (inserting NOPs)
  - **Flushing** (clearing mispredicted instructions)
- [ ] Review **branch prediction techniques**:
  - Static prediction (predict-not-taken / predict-taken)
  - Dynamic prediction (2-bit saturating counters)
- [ ] Analyze pipelined datapath diagrams
- [ ] Review OTTER’s existing pipeline stages and Control Unit (CU)

---

## Implementation Tasks

### 1. Branch Instruction Support
- [ ] Extend the **Control Unit (CU)** to handle BEQ, BNE, etc.
- [ ] Add **branch detection logic** using the `zero` signal from the ALU.
- [ ] Connect and verify `IG`, `BCG`, and `BAG` signals correctly.
- [ ] Implement **branch prediction logic**.

### 2. Jump Instruction Support
- [ ] Implement jump handling for `JAL` and `JALR`.
- [ ] Ensure the immediate offset and PC+4 calculation logic is correct.
- [ ] Connect jumps to the CU and pipeline control.

### 3. Branch Prediction
- [ ] Choose and implement a prediction method (e.g., static or 2-bit dynamic).
- [ ] Integrate prediction logic into the **IF/ID stage**.
- [ ] Update PC selection and flushing logic on misprediction.

### 4. Forwarding Unit
- [ ] Create a module that detects data dependencies and forwards values as needed.
- [ ] Support:
  - EX hazard (forward from MEM or WB stage)
  - MEM hazard (forward from WB to MEM stage if needed)
- [ ] Integrate forwarding into ALU operand selection.

### 5. Hazard Detection Unit (HDU)
- [ ] Detect **load-use hazards** (e.g., instruction depends on result of a load)
- [ ] Insert **stalls (NOPs)** by freezing PC/IF/ID registers
- [ ] Maintain pipeline correctness

### 6. Flushing Logic
- [ ] On **branch misprediction or jump**, flush:
  - **IF/ID** instruction (turn it into NOP)
  - Optionally flush ID/EX for delayed resolution
- [ ] Clear pipeline registers as needed

---

## Test Strategy

- Run each type of instruction independently (load, store, add, branch, jump)
- Validate forwarding by creating RAW dependencies between back-to-back instructions
- Validate hazard unit by triggering load-use hazards
- Run branching and jump sequences with mispredictions
- Monitor PC changes, flushes, and instruction flow

---

## Notes

- This design **does not require a top-level wrapper or Basys 3 deployment**, but you can add those features later for real-time output.
- Ensure that all new components are **tested in isolation** before full pipeline integration.
- Use waveform analysis to debug stalls, flushes, and forwarding paths.

---

## Suggested Files/Modules to Implement

- `control_unit.sv`
- `forwarding_unit.sv`
- `hazard_detection.sv`
- `branch_predictor.sv`
- `otter_wrapper.sv` (optional)

---

## Suggestions from Ryan 

- Start with **static branch prediction** (e.g., always predict not taken)
- Test pipeline with **bubble-insertion (NOPs)** before trying forwarding
- Keep modules **clean and parameterized** for clarity and reuse
