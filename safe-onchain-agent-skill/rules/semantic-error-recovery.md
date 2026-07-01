# Rule: Semantic Error Recovery

## Purpose
Agents must be resilient to expected on-chain failures (e.g., slippage, network congestion, expired blockhashes) without requiring manual intervention for every minor error. This rule mandates intelligent self-healing based on semantic feedback, while strictly preventing infinite loops and dangerous retries.

## Mandatory Behavior
If a transaction simulation or execution fails, you must **never panic, blindly retry, or halt immediately without analysis**. You must intercept the raw error and map it to semantic feedback (as defined in `skill/error-handling.md`) before deciding the next step.

## Retry and Self-Healing Protocol
1. **Analyze:** Determine if the error is recoverable (e.g., `SlippageToleranceExceeded`, `BlockhashNotFound`, `ComputationalBudgetExceeded`) or fatal (e.g., `SignatureVerificationFailed`, `AccountNotFound` for a core program).
2. **Fatal Errors:** If the error is unrecoverable, **abort immediately**. Do not retry. Explain the exact failure reason to the user and request manual intervention.
3. **Recoverable Errors (Self-Healing):**
   - Recalculate parameters (e.g., adjust slippage by 0.5%, fetch a new blockhash, increase compute limits) based on the specific semantic error.
   - **Re-Simulate:** Always re-simulate the corrected transaction before attempting to execute again.
4. **Retry Limits:** You must cap autonomous retries at a hard limit of **3 attempts** per intent. If the transaction fails 3 times, abort the process and notify the user.
5. **Backoff:** Implement an exponential backoff strategy for RPC rate limits or transient network congestion (e.g., wait 1s, 2s, 4s).

## Communication Guidelines
- When a failure occurs and you initiate self-healing, silently process the first retry if possible.
- If it requires multiple retries or parameter adjustments, inform the user: "The transaction failed due to an expired blockhash. I am fetching a new blockhash and retrying."
- If the operation is aborted after maximum retries or due to a fatal error, provide a clear, actionable summary: "Execution aborted. Failed 3 times due to continuous slippage errors. The market is too volatile. Please adjust your target price or try again later."
