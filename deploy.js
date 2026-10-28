require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { ethers } = require('ethers');
const solc = require('solc');

const RPC_URL = process.env.RPC_URL || 'https://rpc.botchain.ai';
const CHAIN_ID = Number(process.env.CHAIN_ID) || 677;
const REPO_URL = 'https://github.com/ntttttbl123-blip/agent-treasury-vault';

async function main() {
    console.log('====================================================');
    console.log('🤖 AGENT TREASURY VAULT: AUTOMATED DEPLOYER');
    console.log('====================================================\n');

    // 1. Verify Private Key
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey || privateKey.trim() === '' || privateKey.includes('PASTE_YOUR_PRIVATE_KEY_HERE')) {
        console.error('❌ Error: PRIVATE_KEY is missing or invalid in .env!');
        console.error('👉 Please open .env and set PRIVATE_KEY=0xYourPrivateKey');
        process.exitCode = 1;
        return;
    }

    // 2. Setup Provider & Wallet
    const provider = new ethers.JsonRpcProvider(RPC_URL, {
        name: 'BOT Chain',
        chainId: CHAIN_ID
    });

    const wallet = new ethers.Wallet(privateKey.trim(), provider);
    console.log(`🔑 Deployer Wallet:  ${wallet.address}`);

    const balanceWei = await provider.getBalance(wallet.address);
    const balanceBot = ethers.formatEther(balanceWei);
    console.log(`💰 Wallet Balance:    ${balanceBot} BOT`);

    if (balanceWei < ethers.parseEther('0.003')) {
        console.error(`\n❌ Error: Insufficient funds for deployment!`);
        console.error(`Current balance: ${balanceBot} BOT`);
        console.error(`Estimated deployment cost: ~0.003 - 0.005 BOT.`);
        console.error(`Please fund ${wallet.address} with BOT tokens before running.`);
        process.exitCode = 1;
        return;
    }

    // 3. Compile Contract
    console.log('\n⚙️  Compiling AgentTreasuryVault.sol (EVM target: paris)...');
    const contractPath = path.join(__dirname, 'AgentTreasuryVault.sol');
    const source = fs.readFileSync(contractPath, 'utf8');

    const input = {
        language: 'Solidity',
        sources: {
            'AgentTreasuryVault.sol': { content: source }
        },
        settings: {
            optimizer: { enabled: true, runs: 200 },
            evmVersion: 'paris',
            outputSelection: {
                '*': {
                    '*': ['abi', 'evm.bytecode.object']
                }
            }
        }
    };

    const output = JSON.parse(solc.compile(JSON.stringify(input)));

    if (output.errors) {
        const errors = output.errors.filter(e => e.severity === 'error');
        if (errors.length > 0) {
            console.error('❌ Compilation errors:');
            errors.forEach(e => console.error(e.formattedMessage));
            process.exit(1);
        }
    }

    const compiled = output.contracts['AgentTreasuryVault.sol']['AgentTreasuryVault'];
    const abi = compiled.abi;
    const bytecode = compiled.evm.bytecode.object;
    console.log('✅ Compilation successful!');

    // 4. Configure Constructor Parameters
    const agentAddress = process.env.AGENT_ADDRESS && ethers.isAddress(process.env.AGENT_ADDRESS)
        ? process.env.AGENT_ADDRESS
        : wallet.address; // default agent to deployer if not specified

    const dailyAllowance = ethers.parseEther(process.env.DAILY_ALLOWANCE || '0.01');
    const maxPerTx = ethers.parseEther(process.env.MAX_PER_TX || '0.005');
    const whitelistEnforced = false;

    console.log('\n📋 Constructor Configuration:');
    console.log(`- Agent Address:       ${agentAddress}`);
    console.log(`- Daily Allowance:     ${ethers.formatEther(dailyAllowance)} BOT`);
    console.log(`- Max Per Tx:          ${ethers.formatEther(maxPerTx)} BOT`);
    console.log(`- Whitelist Enforced:  ${whitelistEnforced}`);

    // 5. Deploy Contract
    console.log('\n🚀 Broadcasting deployment transaction to BOT Chain...');
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    const contract = await factory.deploy(
        agentAddress,
        dailyAllowance,
        maxPerTx,
        whitelistEnforced
    );

    console.log(`⏳ Tx Hash: ${contract.deploymentTransaction().hash}`);
    console.log('Waiting for block confirmation...');

    await contract.waitForDeployment();
    const contractAddress = await contract.getAddress();

    console.log('\n====================================================');
    console.log('🎉 CONTRACT DEPLOYED SUCCESSFULLY!');
    console.log('====================================================');
    console.log(`Contract Address: ${contractAddress}`);
    console.log(`BOTScan Explorer: https://scan.botchain.ai/address/${contractAddress}`);

    // 6. Update tally.json
    console.log('\n📝 Generating tally.json provenance file...');
    const tallyData = {
        contracts: [
            {
                network: 'bot',
                address: contractAddress,
                registeredBy: wallet.address
            }
        ]
    };
    fs.writeFileSync(path.join(__dirname, 'tally.json'), JSON.stringify(tallyData, null, 2));
    console.log('✅ tally.json created!');

    // 7. Update README.md
    console.log('📝 Updating README.md with contract address and badges...');
    const readmePath = path.join(__dirname, 'README.md');
    let readme = fs.readFileSync(readmePath, 'utf8');
    readme = readme.replace(/CONTRACT_ADDRESS_PLACEHOLDER/g, contractAddress);
    fs.writeFileSync(readmePath, readme);
    console.log('✅ README.md updated!');

    // 8. Commit and Push to GitHub
    console.log('\n🔄 Committing and pushing updates to GitHub...');
    try {
        execSync('git add tally.json README.md', { cwd: __dirname });
        execSync(`git commit -m "Configure tally.json and update badges for ${contractAddress}"`, { cwd: __dirname });
        execSync('git push origin main', { cwd: __dirname });
        console.log('✅ Pushed to https://github.com/ntttttbl123-blip/agent-treasury-vault');
    } catch (err) {
        console.warn('⚠️  Could not automatically push to git (you can push manually):', err.message);
    }

    // 9. Instructions for Tally Final Step
    console.log('\n====================================================');
    console.log('🏁 FINAL STEP: COMPLETE REGISTRATION ON TALLY');
    console.log('====================================================');
    console.log('1. Open: https://tallyarc.tech/register?chain=bot');
    console.log(`2. Contract Address: ${contractAddress}`);
    console.log(`3. Repo URL:         ${REPO_URL}`);
    console.log('4. Click "Check what can be proven" -> "Sign and register"');
    console.log('\nYour contract record will immediately show "TALLY VERIFIED" (Green)! 🟢\n');
}

main().catch(err => {
    console.error('\n❌ Deployment failed:', err);
    process.exit(1);
});
