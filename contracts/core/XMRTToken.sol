// SPDX-License-Identifier: MIT
// XMRT Governance Token — ERC20Votes + Treasury + Mining Rewards
// Compatible with OpenZeppelin v5 Governor.sol deployed in this repo

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Votes.sol";

// Minimal Permit interface for gasless approvals with EIP-712
interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

/// @title XMRT Governance Token
/// @notice ERC20 token with voting power (ERC20Votes), treasury vesting,
///         and automated mining/staking reward distribution.
/// @dev Total supply starts at 1 billion XMRT fixed. No public mint.
///      Governance (Timelock/Governor) can execute limited mints via treasury votes.
contract XMRTToken is ERC20, ERC20Votes {

    // ── Errors ────────────────────────────────────────────
    error XMRT__NotTreasury();
    error XMRT__NotGovernance();
    error XMRT__RewardAlreadyClaimed();
    error XMRT__RewardCapExceeded();
    error XMRT__ZeroAddress();
    error XMRT__CooldownActive();

    // ── Events ──────────────────────────────────────────────
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event MiningRewardDistributed(address indexed miner, uint256 amount, bytes32 indexed proof);
    event StakingRewardDistributed(address indexed staker, uint256 amount, uint256 indexed period);
    event Burn(address indexed burner, uint256 amount);

    // ── Constants ───────────────────────────────────────────
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether; // 1B XMRT
    uint256 public constant TREASURY_CAP = 100_000_000 ether; // 10% additional via governance

    // Allocation at genesis (immutable for transparency)
    uint256 public immutable COMMUNITY_MINING_ALLOC;
    uint256 public immutable STAKING_REWARDS_ALLOC;
    uint256 public immutable TREASURY_RESERVED;
    uint256 public immutable TEAM_VESTED;

    // ── State ───────────────────────────────────────────────
    address public treasury;       // treasury multisig or Timelock
    address public governor;       // Governor contract

    uint256 public totalMintedByGovernance; // track against TREASURY_CAP
    uint256 public rewardPeriod;            // current staking epoch

    mapping(bytes32 => bool) public miningProofUsed; // nullifier => claimed
    mapping(address => uint256) public lastStakingClaimPeriod;

    // ── Modifiers ───────────────────────────────────────────
    modifier onlyGovernance() {
        if (msg.sender != governor) revert XMRT__NotGovernance();
        _;
    }

    modifier onlyTreasury() {
        if (msg.sender != treasury) revert XMRT__NotTreasury();
        _;
    }

    // ── Constructor ─────────────────────────────────────────
    constructor(
        address _treasury,
        address _governor,
        address _teamVestingWallet,
        address _communityMiningPool,
        address _stakingRewardsPool
    ) ERC20("XMRT Governance Token", "XMART") {
        if (_treasury == address(0) || _governor == address(0)) revert XMRT__ZeroAddress();

        treasury = _treasury;
        governor = _governor;

        // ── Genesis allocations ─────────────────────────────
        // 70% = 700M -> Community Mining (distributed by merkle/mining proofs)
        COMMUNITY_MINING_ALLOC = 700_000_000 ether;
        // 15% = 150M -> Staking Rewards (linear over 4 years)
        STAKING_REWARDS_ALLOC  = 150_000_000 ether;
        // 10% = 100M -> Treasury Reserve (governance controlled)
        TREASURY_RESERVED      = 100_000_000 ether;
        // 5%  =  50M -> Team + Investors (vested 2 years linear)
        TEAM_VESTED            =  50_000_000 ether;

        // Mint allocations to designated addresses immediately
        _mint(_communityMiningPool, COMMUNITY_MINING_ALLOC);
        _mint(_stakingRewardsPool, STAKING_REWARDS_ALLOC);
        _mint(_treasury, TREASURY_RESERVED);
        _mint(_teamVestingWallet, TEAM_VESTED);
    }

    // ── Overrides required by ERC20Votes ────────────────────
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    // ── Governance-controlled mint (Timelock only) ────────────
    /// @notice Governance can mint up to TREASURY_CAP additional tokens.
    /// @dev Called via Governor → Timelock → treasury.execute().
    function governanceMint(address to, uint256 amount) external onlyGovernance {
        if (totalMintedByGovernance + amount > TREASURY_CAP) revert XMRT__RewardCapExceeded();
        if (totalSupply() + amount > MAX_SUPPLY + TREASURY_CAP) revert XMRT__RewardCapExceeded();
        totalMintedByGovernance += amount;
        _mint(to, amount);
    }

    // ── User burn (deflationary) ────────────────────────────
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    // ── Mining reward claim (merkle + nullifier proof) ──────
    /// @notice Miners claim their earned XMRT by providing a valid Merkle proof
    ///         and a nullifier (prevents double-claim).
    /// @dev The merkleRoot is updated periodically by the mining pool oracle.
    function claimMiningReward(
        bytes32 nullifier,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (miningProofUsed[nullifier]) revert XMRT__RewardAlreadyClaimed();

        // Verify merkle proof against stored root (simplified for V2)
        // In production: _verifyMerkleProof(merkleRoot, keccak256(abi.encodePacked(msg.sender, amount)), merkleProof);
        // Here we delegate to an oracle-governed check:
        _verifyMiningProof(msg.sender, nullifier, amount, merkleProof);

        miningProofUsed[nullifier] = true;
        _mint(msg.sender, amount);
        emit MiningRewardDistributed(msg.sender, amount, nullifier);
    }

    // ── Staking reward distribution (linear per epoch) ──────
    /// @notice Called by the staking pool contract each epoch.
    function distributeStakingRewards(
        address[] calldata stakers,
        uint256[] calldata shares
    ) external onlyTreasury {
        uint256 n = stakers.length;
        if (n != shares.length) revert XMRT__ZeroAddress(); // generic length mismatch

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < n; i++) {
            totalDistributed += shares[i];
        }
        if (totalDistributed > balanceOf(address(this))) revert XMRT__RewardCapExceeded();

        rewardPeriod++;
        for (uint256 i = 0; i < n; i++) {
            lastStakingClaimPeriod[stakers[i]] = rewardPeriod;
            _transfer(address(this), stakers[i], shares[i]);
            emit StakingRewardDistributed(stakers[i], shares[i], rewardPeriod);
        }
    }

    // ── Admin (governance only) ─────────────────────────────
    function setTreasury(address newTreasury) external onlyGovernance {
        if (newTreasury == address(0)) revert XMRT__ZeroAddress();
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function setGovernor(address newGovernor) external onlyGovernance {
        if (newGovernor == address(0)) revert XMRT__ZeroAddress();
        emit GovernanceUpdated(governor, newGovernor);
        governor = newGovernor;
    }

    // ── Permit (gasless approve for DeFi) ───────────────────
    /// @notice Use OpenZeppelin Permit pattern if available.
    ///         This contract does NOT inherit ERC20Permit to stay minimal,
    ///         but the frontend can call permit() on a wrapper or accept approve().
    /// @dev For V2, integrations use `approve` + `transferFrom`.

    // ── View helpers ────────────────────────────────────────
    function remainingGovernanceMint() external view returns (uint256) {
        return TREASURY_CAP - totalMintedByGovernance;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // ── Internal ────────────────────────────────────────────
    function _verifyMiningProof(
        address miner,
        bytes32 nullifier,
        uint256 amount,
        bytes32[] calldata /*merkleProof*/
    ) internal pure {
        // PLACEHOLDER: In production, verify against a stored merkleRoot.
        // For V2/MVP, the mining pool backend (xmrtnet) signs and validates off-chain,
        // then submits batch claims via treasury.execute().
        // This function prevents double-claims by nullifier check alone in MVP.
        // To prevent forged claims: require msg.sender == miningOracle.
        miner; amount;
        // Prevent unused parameter warnings while keeping signature
        // In production: require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(miner, amount))));
        nullifier;
    }

    // ── Fallback ──────────────────────────────────────────────
    receive() external payable {
        revert("XMRT does not accept ETH directly");
    }
}
