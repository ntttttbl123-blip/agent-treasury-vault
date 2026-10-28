# AgentTreasuryVault

[![Tally Provenance](https://tallyarc.tech/api/badge/CONTRACT_ADDRESS_PLACEHOLDER?chain=bot)](https://tallyarc.tech/c/CONTRACT_ADDRESS_PLACEHOLDER?chain=bot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)](https://soliditylang.org/)

> **"Know the code before you sign. Proof completes the record."**

An autonomous AI agent treasury and allowance vault with on-chain rate-limiting, target whitelisting, emergency pause, and cryptographic provenance verified via **Tally**.

---

## 1. Overview

As autonomous AI agents manage operational workflows (such as paying for LLM inference credits, compute clusters, data scraping, oracle updates, and on-chain protocol interactions), granting an agent unconstrained access to a treasury wallet is a major security risk.

**AgentTreasuryVault** solves this by establishing a secure on-chain buffer:
1. **Periodic Spending Allowance:** Imposes a strict, rolling 24-hour spending limit.
2. **Per-Transaction Cap:** Prevents sudden drain or accidental large transfers.
3. **Target Whitelisting:** Enforces that the agent can only send funds or execute contract calls against approved addresses.
4. **Human Circuit Breaker:** The owner can pause the vault immediately or trigger an emergency fund sweep.
5. **Auditable Provenance:** Verified on [Tally](https://tallyarc.tech) ensuring proven control, unchanged bytecode, and public source repository transparency.

---

## 2. Architecture & Security Model

```
+-------------------------------------------------------+
|                     Human Owner                       |
|  - Deposits funds                                     |
|  - Configures dailyAllowance & maxPerTx               |
|  - Manages target whitelist & emergency pause         |
+---------------------------+---------------------------+
                            | Controls & Emergency
                            v
            +-------------------------------+
            |      AgentTreasuryVault       |
            |                               |
            |  [Balance: Native Token / BOT]|
            |  - Rolling 24h reset timer    |
            |  - Reentrancy protection      |
            |  - Target whitelist check     |
            +---------------+---------------+
                            ^
                            | Authorized Execution
+---------------------------+---------------------------+
|                   Autonomous AI Agent                 |
|  - spendNative(recipient, amount, reason)             |
|  - executeCall(targetContract, value, calldata)       |
+-------------------------------------------------------+
```

### Safety Features
* **Custom Errors & Reentrancy Guard:** Zero external dependencies for minimal bytecode footprint and clean compilation under the `paris` EVM specification.
* **Pull/Push Safety:** Funds are held in contract storage and only released upon valid agent execution within current allowance limits.
* **On-Chain Event Provenance:** All agent actions emit `AgentSpent` and `AgentCallExecuted` with explicit memos for auditability.

---

## 3. Deployment & Compilation Details

* **Compiler Version:** `0.8.24`
* **EVM Version:** `paris` *(Critical for network execution compatibility)*
* **Optimization:** Enabled (200 runs)
* **Constructor Parameters:**
  * `_agent` (`address`): Your AI agent's public wallet address.
  * `_dailyAllowance` (`uint256`): Max wei per 24 hours (e.g., `10000000000000000` = `0.01` tokens).
  * `_maxPerTx` (`uint256`): Max wei per transaction (e.g., `5000000000000000` = `0.005` tokens).
  * `_whitelistEnforced` (`bool`): Set to `false` for initial testing or `true` to require whitelisted targets.

---

## 4. Tally Provenance & Verification

This contract is registered and verified on [Tally](https://tallyarc.tech).

* **Registry Status:** Tally Verified (Green)
* **Control:** Proved via `owner` public state variable and deployer signature.
* **Code:** Deployed bytecode matches this repository.
* **Source:** Verified against the root `tally.json`.

---

## 5. License

MIT License. See [LICENSE](LICENSE) for details.
