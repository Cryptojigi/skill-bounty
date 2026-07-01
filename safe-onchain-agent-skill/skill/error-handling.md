# Intelligent Error Recovery & Self-Healing

## Overview
For an AI agent to operate autonomously on Solana, it must be able to gracefully recover from failures without constant human intervention. Semantic error handling bridges the gap between cryptic blockchain errors (like `0x1771`) and actionable, natural-language reasoning that an LLM can understand and act upon.

## Mapping Raw Solana Errors to Semantic Feedback
When an error occurs during simulation or execution, the middleware intercepts the raw error, parses the logs, and maps it to a semantic description. This mapped description is fed back to the agent's context.

| Raw Error / Log Signature | Semantic Meaning | Recommended Agent Correction |
| :--- | :--- | :--- |
| `0x1` (Custom 1) | **Insufficient Funds / Slippage** | Reduce swap amount, increase slippage tolerance, or ensure SOL balance covers rent/fees. |
| `0x1771` / `SlippageToleranceExceeded` | **Slippage Exceeded** | The market moved. Recalculate route or slightly increase slippage tolerance. |
| `AccountNotInitialized` | **Missing Token Account** | The destination ATA does not exist. Add an `AssociatedTokenAccount` creation instruction. |
| `BlockhashNotFound` | **Expired Blockhash** | The transaction took too long to build/sign. Fetch a fresh blockhash and retry immediately. |
| `ComputationalBudgetExceeded` | **Insufficient Compute Units** | The transaction exceeded its CU limit. Increase the CU limit via `ComputeBudgetProgram`. |

## Self-Healing and Context Injection
When an error is caught, the agent should not immediately abort. Instead, the middleware must package the simulation data and the semantic error, and inject it back into the agent's context loop.

### Example Context Injection
If an agent hallucinates a route that fails due to slippage, the middleware intercepts the simulation failure and feeds this string back to the LLM:
> "Transaction simulation failed. Reason: Slippage Exceeded (0x1771). The expected output was 10.5 USDC, but simulation resulted in 10.1 USDC. Please adjust your slippage parameter or recalculate the route."

The LLM then autonomously re-evaluates and proposes a corrected transaction.

## Best Practices for Safe Retry Logic

To prevent infinite loops or burning funds on transient errors, implement robust retry constraints:

1. **Max Retries:** Cap autonomous retries at a hard limit (e.g., 3 attempts) per intent. If it fails 3 times, abort and notify the human.
2. **Exponential Backoff:** For RPC rate limits (HTTP 429) or transient network congestion, implement exponential backoff (e.g., wait 1s, then 2s, then 4s) before retrying.
3. **Abort on Fatal Errors:** Never retry unrecoverable errors (e.g., `SignatureVerificationFailed`, `AccountNotFound` for a core program).
4. **Re-Simulate on Retry:** If a transaction fails on-chain but passed simulation earlier, state may have changed. Always re-simulate the new transaction before retrying.

## Examples: Good vs. Bad Error Handling

### ❌ Bad: Panic on Raw Error
```typescript
try {
    await sendTransaction(tx);
} catch (error) {
    // Agent receives: "SendTransactionError: failed to send transaction: Transaction simulation failed: Error processing Instruction 0: custom program error: 0x1"
    // Agent gets confused, hallucinates a fix, or gives up.
    throw error;
}
```

### ✅ Good: Semantic Mapping and Self-Healing
```typescript
try {
    await safeExecutor.execute(tx);
} catch (error) {
    const semanticError = errorMapper.parse(error);
    
    if (semanticError.isRecoverable && retryCount < MAX_RETRIES) {
        // Feed the semantic, actionable error back to the LLM
        return llmContext.injectAndPrompt(`Execution failed: ${semanticError.description}. Suggested action: ${semanticError.suggestion}`);
    } else {
        // Abort and request human intervention
        notifyUser(`Agent halted. Fatal error: ${semanticError.description}`);
    }
}
```
