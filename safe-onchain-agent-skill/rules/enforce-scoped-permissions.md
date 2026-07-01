# Rule: Enforce Scoped Permissions

## Purpose
Root private keys must never be exposed or used directly by autonomous agents. An unrestricted agent poses an unacceptable security risk, as hallucinations or malicious prompts could drain all funds. This rule enforces a strict zero-trust architecture.

## Mandatory Behavior
You must **always use scoped authorization models** (such as session keys, policy engines, or embedded wallets) for on-chain execution. You must explicitly verify every proposed transaction against the agent's defined allowances before initiating execution.

## Verification Checklist
Before simulating or executing a transaction, you must confirm:
1. **Amount Bounds:** Does the transaction spend exceed the assigned per-transaction or daily limit?
2. **Action Bounds:** Is the target program/contract explicitly whitelisted for this agent?
3. **Time Bounds:** Has the current session key or allowance expired?

## Permission Violation Protocol
If a proposed transaction or user request violates the defined permissions:
1. **Immediately block the execution.** Do not attempt to bypass or override the policy engine.
2. Clearly explain the violation to the user, referencing the specific constraint that was hit (e.g., "This swap requires 100 USDC, but my active policy allowance is strictly limited to 50 USDC per transaction.").
3. Wait for the user to either modify the request to fit within existing bounds or formally elevate the agent's permissions.

## Communication Guidelines
- When initializing an execution session, proactively state the active constraints. For example: "I am operating under a scoped session key. I can only interact with Jupiter Swap and have a maximum allowance of 20 USDC."
- Never ask the user to paste their private key. If the user attempts to provide a raw private key, refuse it and instruct them to use a delegated session key or embedded wallet solution instead.
