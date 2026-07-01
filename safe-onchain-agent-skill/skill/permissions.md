# Scoped Permissions & Wallet Hygiene

## Overview
Granting an AI agent unchecked access to a root private key is extremely dangerous. A single hallucination or compromised prompt could drain an entire treasury. The Safe On-Chain Agent Skill enforces zero-trust architecture through scoped permissions, session keys, and strict wallet hygiene.

## Why Root Access is Dangerous
Autonomous agents operate on probabilistic LLM logic. They may misinterpret parameters, fall victim to prompt injection attacks, or encounter malicious smart contracts. If an agent holds a standard private key with full balances, the downside risk is total loss of funds.

## Session Keys & Embedded Wallets
Instead of injecting raw secret keys into the agent's environment, production-grade agents should use delegated authorization models:

- **Embedded Wallets (Turnkey, Privy, Coinbase WaaS):** The agent interacts with an API that signs transactions. The API enforces policy constraints (e.g., "deny any transaction exceeding 10 SOL") *before* signing.
- **Session Keys (Squads, Gum, native programs):** The root wallet signs a transaction granting a temporary, throwaway keypair the right to perform specific actions on its behalf. The agent holds the throwaway key.

## Defining Granular Allowances
When provisioning an agent, permissions should be defined as strictly as possible. The middleware checks every simulated transaction against these bounds.

1. **Amount-Bound (Spend Limits):** 
   "Agent is allowed to spend a maximum of 50 USDC per transaction, and 200 USDC per day."
2. **Action-Bound (Contract Whitelists):**
   "Agent may only interact with Jupiter Swap and Meteora DLMM programs. All other program invocations are blocked."
3. **Time-Bound (Expirations):**
   "Session key is valid only for the next 4 hours."

## Zero-Trust Permission Design
- **Default Deny:** Block all transactions unless explicitly permitted by the policy.
- **Isolate Agent Funds:** If session keys or policy engines are unavailable, fund a dedicated "hot" wallet with only the exact amount the agent needs for its immediate task.
- **Middleware Enforcement:** Never rely on the LLM to self-police. The middleware must independently verify the simulated transaction against the policy before allowing the signature.

## Communicating Constraints to the LLM
The agent must be aware of its boundaries so it doesn't waste compute trying to execute forbidden actions. Feed constraints directly into the system prompt.

```text
You are an autonomous trading agent. 
Constraints:
- You may only swap tokens on Jupiter.
- You have a strict allowance of 50 USDC per trade.
- Do not attempt to transfer SOL out of the wallet.
If your proposed transaction violates these constraints, the execution middleware will block it.
```

## Examples: Good vs. Risky Permission Setups

### ❌ Risky: God-Mode Access
```typescript
// DANGEROUS: Giving the agent a raw, unfunded private key array
const agentKeypair = Keypair.fromSecretKey(new Uint8Array([...]));
const agent = new Agent({
    wallet: agentKeypair, // Agent can do absolutely anything with this wallet
});
```

### ✅ Good: Policy-Driven Delegation
```typescript
// SAFE: Agent has no private key. It requests signatures from a policy engine.
const policyEngine = new TurnkeyPolicyEngine({
    allowedPrograms: [JUPITER_V6_PROGRAM_ID],
    maxSpendPerTx: { token: 'USDC', amount: 50 }
});

const safeExecutor = new SafeAgentExecutor(connection, policyEngine);

// The executor simulates the tx, checks it against the policyEngine, 
// and only then requests the remote signature.
await safeExecutor.execute(agentProposedTx);
```
