# Step-by-Step Guide: Deploying and Registering AgentTreasuryVault on Tally

This guide adapts the official Tally registration flow to deploy and register **AgentTreasuryVault** on **BOT Chain** (or any supported EVM network).

---

## What You Need
1. **MetaMask** installed in your browser.
2. **~0.02 BOT** (or native gas tokens) in your wallet for deployment and registration fees.
3. A public GitHub repository (e.g. `https://github.com/yourusername/agent-treasury-vault`) containing the `AgentTreasuryVault.sol` file and `README.md`.

---

## Network Details (BOT Chain)
* **Network name:** BOT Chain
* **RPC URL:** `https://rpc.botchain.ai`
* **Chain ID:** `677`
* **Currency symbol:** `BOT`
* **Block explorer:** `https://scan.botchain.ai`

---

## Step 1: Add BOT Chain & Connect to Tally
1. Open [https://tallyarc.tech/register?chain=bot](https://tallyarc.tech/register?chain=bot).
2. Click **"Connect wallet"** in the top right.
3. Approve the connection in MetaMask and allow it to switch to **BOT Chain** (Chain ID 677).
4. Keep this tab open.

---

## Step 2: Compile & Deploy via Remix (5 minutes)

1. Open [Remix IDE](https://remix.ethereum.org).
2. In the file explorer, create a new file named `AgentTreasuryVault.sol`.
3. Copy and paste the entire code from [`AgentTreasuryVault.sol`](./AgentTreasuryVault.sol) into Remix.
4. Go to the **Solidity Compiler** tab (left sidebar):
   - **Compiler version:** Select `0.8.24`.
   - Click **Advanced Configurations**:
     - Set **EVM Version** to **`paris`** *(Crucial: BOT Chain requires the paris EVM target).*
   - Click **Compile AgentTreasuryVault.sol**.
5. Go to the **Deploy & Run Transactions** tab:
   - **Environment:** Select **"Injected Provider - MetaMask"**.
   - Ensure MetaMask indicates you are connected to BOT Chain (Chain 677).
   - In the **Contract** dropdown, choose `AgentTreasuryVault`.
   - In the constructor parameters box (expand the arrow next to Deploy), fill in:
     - `_agent`: Your agent's wallet address (you can use your own secondary address or test address).
     - `_dailyAllowance`: `10000000000000000` *(0.01 BOT in wei)*.
     - `_maxPerTx`: `5000000000000000` *(0.005 BOT in wei)*.
     - `_whitelistEnforced`: `false` *(allows unrestricted testing initially)*.
   - *(Optional)* In the **Value** field at the top, enter `0.005` BOT to pre-fund the vault upon deployment.
6. Click **Deploy** (or **transact**).
7. Confirm the transaction in MetaMask.
8. Once mined, find the contract under **Deployed Contracts** in Remix and click the copy icon next to its address. Save this address.

---

## Step 3: Register on Tally (3 minutes)

1. Switch back to [https://tallyarc.tech/register?chain=bot](https://tallyarc.tech/register?chain=bot).
2. **Contract Address:** Paste the contract address you just copied from Remix.
3. **Repository URL:** Paste your public GitHub repository link (e.g. `https://github.com/yourusername/agent-treasury-vault`).
4. Click **"Check what can be proven"**.
   - Tally will inspect the live contract on BOT Chain and confirm that your connected wallet is the `owner`.
5. Check the confirmation checkbox and click **"Sign and register"**.
6. Sign the off-chain EIP-712 message in MetaMask (costs $0 gas).
7. Approve the on-chain registry transaction in MetaMask (~0.0045 BOT).
8. Once the transaction confirms, the page will display **"Registered"** with a **"View transaction"** link.

---

## Step 4: Make It "Tally Verified" (Green Status)

1. After registering, the Tally page displays a small `tally.json` snippet.
2. In your GitHub repository:
   - Create a file named `tally.json` in the root directory.
   - Paste the exact snippet shown on the Tally page.
   - Commit and push to `main`.
3. In your `README.md`, update the badge link with your contract address:
   ```markdown
   [![Tally Provenance](https://tallyarc.tech/api/badge/0xYOUR_CONTRACT_ADDRESS?chain=bot)](https://tallyarc.tech/c/0xYOUR_CONTRACT_ADDRESS?chain=bot)
   ```
4. Refresh your record page on `https://tallyarc.tech/c/0xYOUR_CONTRACT_ADDRESS?chain=bot`.
5. The badge will switch to **Tally Verified** (green)!

---

## Troubleshooting Checklist
* **"Insufficient funds":** You need ~0.02 BOT in your wallet for network fees.
* **"The page says your wallet cannot prove control":** Ensure the MetaMask account connected to Tally is the exact same account that deployed the contract in Remix.
* **Remix deployment failure:** Verify that the compiler is set to `0.8.24` and EVM version is explicitly set to `paris`.
