# Example: Self-Healing Jupiter Swap

This example demonstrates how an AI agent equipped with the **Safe On-Chain Agent Skill** handles a typical token swap, specifically showcasing the middleware's ability to intercept failures and the agent's ability to self-correct.

## 1. The User Prompt
> **User:** "Swap 10 USDC for SOL on Jupiter using my active session key."

## 2. Agent Execution Flow

### Step 1: Pre-Flight Validation & Routing
The agent determines the current USDC balance and fetches a route from the Jupiter API for exactly 10 USDC to SOL, applying a default 0.1% slippage.

### Step 2: Simulation-First Execution (Failure)
Following the `.claude/rules/always-simulate-before-signing.md` rule, the agent proposes the transaction to the middleware for simulation against live mainnet state.

**Agent Action:**
> "I have calculated the route for 10 USDC to SOL. I will now simulate this transaction to ensure safety."

**Middleware Result:**
> ❌ **Simulation Failed:** `SlippageToleranceExceeded` (0x1771). The market moved during route calculation. Expected minimum out was 0.065 SOL, but the simulation yielded 0.0648 SOL.

### Step 3: Semantic Error Recovery (Self-Healing)
Instead of aborting or blindly retrying, the middleware maps the raw `0x1771` error into semantic context and injects it back into the LLM.

**Agent Self-Correction:**
> "The initial simulation failed because the slippage tolerance was exceeded. I have autonomously adjusted the slippage tolerance from 0.1% to 0.5% and fetched a new route."

### Step 4: Re-Simulation & Safe Execution
The agent submits the revised transaction.

**Middleware Result:**
> ✅ **Simulation Passed:** Transaction requires 55,000 Compute Units. No program errors. Slippage parameters are within bounds.

**Agent Action:**
> "The revised simulation was successful. Executing the safe transaction now..."
> *(Transaction is signed using the scoped session key and broadcasted to mainnet).*

## Key Safety Steps Taken
- **No Blind Signing:** The initial route would have failed on-chain, costing the user transaction fees. Simulation prevented this.
- **Zero-Trust Policy:** The agent used a scoped session key rather than holding a root private key.
- **Intelligent Error Recovery:** The agent used semantic feedback to adjust parameters, resolving a transient issue without bothering the user for manual intervention.
