// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XenovaDistributor is ReentrancyGuard {
    using SafeMath for uint256;

    // Batch processing constants
    uint256 public constant BATCH_SIZE = 500;
    uint256 public constant SNAPSHOT_WINDOW = 1 days;
    uint256 public constant DISTRIBUTION_WINDOW = 10 days;

    // Distribution state
    struct DistributionInfo {
        uint256 snapshotTimestamp;
        uint256 totalStaked;
        uint256 xenPerShare;
        uint256 totalDistributed;
        bool snapshotTaken;
        bool distributionComplete;
    }

    // Track annual and final distributions
    mapping(uint256 => DistributionInfo) public distributions; // year => info
    mapping(uint256 => mapping(address => uint256)) public stakedAtSnapshot; // year => user => amount
    mapping(uint256 => mapping(address => bool)) public hasClaimed; // year => user => claimed

    // Events
    event SnapshotStarted(uint256 indexed year, uint256 timestamp);
    event SnapshotCompleted(uint256 indexed year, uint256 totalStaked, uint256 xenPerShare);
    event DistributionProcessed(uint256 indexed year, uint256 batchIndex, uint256 processedCount);
    event RewardsClaimed(address indexed user, uint256 indexed year, uint256 amount);

    // Take snapshot of all stakers
    function takeSnapshot(uint256 year) external {
        require(!distributions[year].snapshotTaken, "Snapshot already taken");
        require(
            year == 0 || distributions[year - 1].distributionComplete,
            "Previous year not complete"
        );

        DistributionInfo storage dist = distributions[year];
        dist.snapshotTimestamp = block.timestamp;
        dist.snapshotTaken = true;

        emit SnapshotStarted(year, block.timestamp);
    }

    // Process stakers in batches during snapshot window
    function processSnapshotBatch(
        uint256 year,
        address[] calldata stakers,
        uint256 batchIndex
    ) external {
        DistributionInfo storage dist = distributions[year];
        require(dist.snapshotTaken, "Snapshot not started");
        require(
            block.timestamp <= dist.snapshotTimestamp + SNAPSHOT_WINDOW,
            "Snapshot window closed"
        );
        require(stakers.length <= BATCH_SIZE, "Batch too large");

        uint256 batchTotal = 0;

        for(uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakedAmount = stakingContract.getStakedAmount(staker);
            
            if(stakedAmount > 0) {
                stakedAtSnapshot[year][staker] = stakedAmount;
                batchTotal = batchTotal.add(stakedAmount);
            }
        }

        dist.totalStaked = dist.totalStaked.add(batchTotal);
        
        emit DistributionProcessed(year, batchIndex, stakers.length);
    }

    // Finalize snapshot and calculate shares
    function finalizeSnapshot(uint256 year, uint256 xenAmount) external {
        DistributionInfo storage dist = distributions[year];
        require(dist.snapshotTaken, "Snapshot not taken");
        require(
            block.timestamp > dist.snapshotTimestamp + SNAPSHOT_WINDOW,
            "Snapshot window active"
        );
        require(dist.totalStaked > 0, "No stakers found");
        require(xenAmount > 0, "Invalid XEN amount");

        // Calculate XEN per staked XENOVA
        dist.xenPerShare = xenAmount.mul(1e18).div(dist.totalStaked);
        
        emit SnapshotCompleted(year, dist.totalStaked, dist.xenPerShare);
    }

    // Claim distribution
    function claimDistribution(uint256 year) external nonReentrant {
        DistributionInfo storage dist = distributions[year];
        require(dist.xenPerShare > 0, "Distribution not ready");
        require(!hasClaimed[year][msg.sender], "Already claimed");
        
        uint256 stakedAmount = stakedAtSnapshot[year][msg.sender];
        require(stakedAmount > 0, "Nothing to claim");

        // Calculate share
        uint256 share = stakedAmount.mul(dist.xenPerShare).div(1e18);
        require(share > 0, "Zero share");

        // Mark as claimed
        hasClaimed[year][msg.sender] = true;
        dist.totalDistributed = dist.totalDistributed.add(share);

        // Transfer XEN
        require(
            xenContract.transfer(msg.sender, share),
            "Transfer failed"
        );

        emit RewardsClaimed(msg.sender, year, share);
    }

    // View functions
    function getStakerInfo(
        uint256 year,
        address staker
    ) external view returns (
        uint256 stakedAmount,
        uint256 pendingReward,
        bool claimed
    ) {
        stakedAmount = stakedAtSnapshot[year][staker];
        claimed = hasClaimed[year][staker];
        
        if (stakedAmount > 0 && !claimed && distributions[year].xenPerShare > 0) {
            pendingReward = stakedAmount
                .mul(distributions[year].xenPerShare)
                .div(1e18);
        }
    }

    function getDistributionProgress(
        uint256 year
    ) external view returns (
        uint256 totalStakers,
        uint256 claimedCount,
        uint256 remainingXen
    ) {
        DistributionInfo storage dist = distributions[year];
        
        return (
            dist.totalStaked,
            dist.totalDistributed,
            xenContract.balanceOf(address(this))
        );
    }
}