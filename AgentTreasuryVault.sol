// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title AgentTreasuryVault
 * @notice An autonomous AI agent treasury and allowance vault with rate-limiting,
 *         target whitelisting, emergency pause, and proven on-chain provenance.
 * @dev Fully standalone (no external imports needed), compatible with EVM target "paris"
 *      and verified under Tally provenance standards.
 */
contract AgentTreasuryVault {
    // --- State Variables ---

    address public owner;
    address public agent;

    uint256 public dailyAllowance;
    uint256 public maxPerTx;
    uint256 public spentInCurrentPeriod;
    uint256 public currentPeriodStart;
    uint256 public constant PERIOD_DURATION = 1 days;

    bool public paused;
    bool public whitelistEnforced;

    mapping(address => bool) public isWhitelistedTarget;

    uint256 private _locked = 1;

    // --- Events ---

    event OwnerUpdated(address indexed previousOwner, address indexed newOwner);
    event AgentUpdated(address indexed previousAgent, address indexed newAgent);
    event AllowanceUpdated(uint256 newDailyAllowance, uint256 newMaxPerTx);
    event WhitelistTargetUpdated(address indexed target, bool isWhitelisted);
    event WhitelistEnforcementUpdated(bool enforced);
    event VaultPaused(address indexed account);
    event VaultUnpaused(address indexed account);
    event Deposited(address indexed sender, uint256 amount);
    event AgentSpent(address indexed recipient, uint256 amount, string reason);
    event AgentCallExecuted(address indexed target, uint256 value, bytes data, bool success);
    event EmergencyWithdrawal(address indexed to, uint256 amount);
    event EmergencyTokenWithdrawal(address indexed token, address indexed to, uint256 amount);

    // --- Custom Errors ---

    error Unauthorized();
    error VaultIsPaused();
    error TargetNotWhitelisted(address target);
    error ExceedsPerTxCap(uint256 amount, uint256 cap);
    error ExceedsDailyAllowance(uint256 requested, uint256 remaining);
    error TransferFailed();
    error CallExecutionFailed(bytes returnData);
    error ReentrancyGuard();
    error ZeroAddress();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyAgent() {
        if (msg.sender != agent) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert VaultIsPaused();
        _;
    }

    modifier nonReentrant() {
        if (_locked != 1) revert ReentrancyGuard();
        _locked = 2;
        _;
        _locked = 1;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the treasury vault.
     * @param _agent Address of the authorized AI agent wallet.
     * @param _dailyAllowance Maximum native currency (in wei) the agent can spend per 24 hours.
     * @param _maxPerTx Maximum native currency (in wei) allowed per single transaction.
     * @param _whitelistEnforced If true, agent can only transfer/call whitelisted targets.
     */
    constructor(
        address _agent,
        uint256 _dailyAllowance,
        uint256 _maxPerTx,
        bool _whitelistEnforced
    ) payable {
        if (_agent == address(0)) revert ZeroAddress();

        owner = msg.sender;
        agent = _agent;
        dailyAllowance = _dailyAllowance;
        maxPerTx = _maxPerTx;
        whitelistEnforced = _whitelistEnforced;

        currentPeriodStart = block.timestamp;

        emit OwnerUpdated(address(0), msg.sender);
        emit AgentUpdated(address(0), _agent);
        emit AllowanceUpdated(_dailyAllowance, _maxPerTx);
        emit WhitelistEnforcementUpdated(_whitelistEnforced);

        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    // --- Receive & Deposit ---

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    // --- Agent Actions ---

    /**
     * @notice Allows the authorized AI agent to transfer native funds to a recipient.
     * @param recipient The target recipient address.
     * @param amount Amount in wei to send.
     * @param reason Memo / metadata string describing the action (e.g. "Compute API credit renewal").
     */
    function spendNative(
        address payable recipient,
        uint256 amount,
        string calldata reason
    ) external onlyAgent whenNotPaused nonReentrant {
        if (recipient == address(0)) revert ZeroAddress();
        if (whitelistEnforced && !isWhitelistedTarget[recipient]) {
            revert TargetNotWhitelisted(recipient);
        }

        _deductAllowance(amount);

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit AgentSpent(recipient, amount, reason);
    }

    /**
     * @notice Allows the authorized AI agent to call arbitrary methods on whitelisted contracts.
     * @param target Target contract address.
     * @param value Native currency in wei sent along with the call.
     * @param data Calldata payload for the contract invocation.
     * @return returnData The bytes returned from the target call.
     */
    function executeCall(
        address payable target,
        uint256 value,
        bytes calldata data
    ) external onlyAgent whenNotPaused nonReentrant returns (bytes memory returnData) {
        if (target == address(0)) revert ZeroAddress();
        if (whitelistEnforced && !isWhitelistedTarget[target]) {
            revert TargetNotWhitelisted(target);
        }

        if (value > 0) {
            _deductAllowance(value);
        }

        bool success;
        (success, returnData) = target.call{value: value}(data);
        if (!success) revert CallExecutionFailed(returnData);

        emit AgentCallExecuted(target, value, data, success);
    }

    // --- View Functions ---

    /**
     * @notice Returns remaining spending allowance available in the current 24-hour cycle.
     */
    function getRemainingAllowance() public view returns (uint256) {
        if (block.timestamp >= currentPeriodStart + PERIOD_DURATION) {
            return dailyAllowance;
        }
        if (spentInCurrentPeriod >= dailyAllowance) {
            return 0;
        }
        return dailyAllowance - spentInCurrentPeriod;
    }

    /**
     * @notice Returns total vault balance in native currency.
     */
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Owner Management Functions ---

    function setAgent(address newAgent) external onlyOwner {
        if (newAgent == address(0)) revert ZeroAddress();
        emit AgentUpdated(agent, newAgent);
        agent = newAgent;
    }

    function setAllowance(uint256 newDailyAllowance, uint256 newMaxPerTx) external onlyOwner {
        dailyAllowance = newDailyAllowance;
        maxPerTx = newMaxPerTx;
        emit AllowanceUpdated(newDailyAllowance, newMaxPerTx);
    }

    function setTargetWhitelist(address target, bool status) external onlyOwner {
        if (target == address(0)) revert ZeroAddress();
        isWhitelistedTarget[target] = status;
        emit WhitelistTargetUpdated(target, status);
    }

    function setWhitelistEnforced(bool status) external onlyOwner {
        whitelistEnforced = status;
        emit WhitelistEnforcementUpdated(status);
    }

    function pause() external onlyOwner {
        paused = true;
        emit VaultPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit VaultUnpaused(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    function emergencyWithdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        uint256 balance = address(this).balance;
        uint256 toWithdraw = amount > balance ? balance : amount;

        (bool success, ) = to.call{value: toWithdraw}("");
        if (!success) revert TransferFailed();

        emit EmergencyWithdrawal(to, toWithdraw);
    }

    function emergencyWithdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (token == address(0) || to == address(0)) revert ZeroAddress();

        // Standard ERC-20 transfer call
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }

        emit EmergencyTokenWithdrawal(token, to, amount);
    }

    // --- Internal Helpers ---

    function _deductAllowance(uint256 amount) internal {
        if (maxPerTx > 0 && amount > maxPerTx) {
            revert ExceedsPerTxCap(amount, maxPerTx);
        }

        if (block.timestamp >= currentPeriodStart + PERIOD_DURATION) {
            currentPeriodStart = block.timestamp;
            spentInCurrentPeriod = 0;
        }

        uint256 remaining = dailyAllowance >= spentInCurrentPeriod
            ? dailyAllowance - spentInCurrentPeriod
            : 0;

        if (amount > remaining) {
            revert ExceedsDailyAllowance(amount, remaining);
        }

        spentInCurrentPeriod += amount;
    }
}
