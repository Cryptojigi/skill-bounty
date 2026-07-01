# Simulation-First Execution

## Overview
Simulation is the core safety mechanism in the Safe On-Chain Agent Skill. By dry-running transactions against the live Solana mainnet state *before* requesting user signatures, we can predict exact outcomes, prevent failed transactions, and eliminate unnecessary compute fees.

## Structuring Simulation Requests
To accurately simulate a transaction, construct a standard request using the `simulateTransaction` RPC method.

```typescript
const { value: simResult } = await connection.simulateTransaction(transaction, {
    sigVerify: false,                     // Do not require valid signatures for simulation
    replaceRecentBlockhash: true,         // Ensure it simulates even if the blockhash is slightly old
    commitment: 'confirmed',              // Use confirmed state to avoid simulating against dropped forks
    innerInstructions: true,              // Crucial for debugging complex DeFi routes
    returnAccounts: true                  // Fetch state changes for specific accounts
});
```

## What to Check in Simulation Results

Before allowing an agent to proceed with signing or execution, the middleware must validate the following fields:

- **Compute Units (CU):** 
  Check `simResult.unitsConsumed`. Ensure the transaction's requested compute budget is greater than the consumed units (include a 10% safety buffer).
- **Program Errors (`err`):** 
  If `simResult.err` is not null, the transaction will definitively fail.
- **Slippage & Balances:** 
  If using `returnAccounts`, compare the pre- and post-balances of the token accounts involved. Ensure the output amount meets the user's minimum expected return (slippage tolerance).
- **Logs (`logs`):** 
  Scan `simResult.logs` for `insufficient funds`, `slippage exceeded`, or program-specific panics.

## Interpreting Common Simulation Failures

When `simResult.err` is present, use the logs to diagnose the issue:

| Error / Log Signature | Meaning | Agent Action |
| :--- | :--- | :--- |
| `InstructionError: [0, {"Custom": 1}]` (0x1) | Insufficient funds or slippage threshold violated. | Recalculate route, increase slippage slightly, or reduce input amount. |
| `InstructionError: [0, "AccountNotInitialized"]` | Trying to send tokens to an ATA that doesn't exist. | Add an `AssociatedTokenAccount` creation instruction to the transaction. |
| `Exceeded CUs` / `ComputationalBudgetExceeded` | The transaction ran out of compute units. | Add `ComputeBudgetProgram.setComputeUnitLimit` with a higher limit. |
| `BlockhashNotFound` | The blockhash expired during simulation prep. | Fetch a new blockhash and reconstruct. |

## Examples: Good vs. Bad Handling

### ❌ Bad: Blind Execution
```typescript
// The agent hallucinates a route and blindly sends it
const txid = await connection.sendTransaction(tx, [keypair]);
// Result: Fails on-chain, user loses transaction fees, execution halts.
```

### ✅ Good: Simulation-First Adjustment
```typescript
// 1. Simulate first
const sim = await connection.simulateTransaction(tx, config);

if (sim.value.err) {
    if (sim.value.logs.some(l => l.includes("Exceeded CUs"))) {
        // 2. Adjust parameters based on simulation data
        const safeLimit = Math.ceil(sim.value.unitsConsumed * 1.15);
        tx.add(ComputeBudgetProgram.setComputeUnitLimit({ units: safeLimit }));
        
        // 3. Re-simulate or proceed to safe execution
        await executor.safeExecute(tx);
    } else {
        throw new Error("Simulation failed for unrecoverable reason.");
    }
}
```

## Best Practices
- **Never bypass simulation:** Even "simple" transfers should be simulated to ensure the destination account is valid.
- **Provide semantic feedback:** If a simulation fails, the middleware should feed the specific reason (e.g., "Slippage exceeded by 0.5%") back to the LLM context so the agent can reason about the fix.
- **Fail securely:** If a simulation fails and cannot be auto-corrected, abort the operation entirely and notify the user.
