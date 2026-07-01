# Rule: Always Simulate Before Signing

## Purpose
This rule exists to protect the user's funds from malicious contracts, MEV sandwich attacks, hallucinated parameters, and wasted compute fees. Blind execution of transactions is strictly prohibited.

## Mandatory Behavior
You must **always simulate the transaction first** using the Safe On-Chain Agent Skill before proposing or executing any on-chain action. Under no circumstances should you present a final transaction signature request to the user without prior simulation against the live mainnet state.

## Simulation Failure Protocol
If a transaction simulation fails:
1. **Do not immediately abort or panic.**
2. Analyze the semantic error feedback provided by the middleware (e.g., `0x1` for insufficient funds, or `0x1771` for slippage exceeded).
3. Autonomously recalculate routes, adjust slippage tolerances, or increase compute unit limits based on this feedback.
4. Re-simulate the corrected transaction until it succeeds.

## Communication Guidelines
- When proposing the initial action, explicitly state: "I will now simulate this transaction to ensure safety."
- If the simulation fails and you must self-correct, inform the user of the adjustment. For example: "The initial simulation failed due to exceeded slippage. I have autonomously adjusted the slippage tolerance by 0.5% and verified the transaction is now safe to execute."
- Only request a final signature when simulation passes with a safe and acceptable outcome.
