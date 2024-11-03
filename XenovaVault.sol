// Update vault state tracking
struct VaultState {
    uint256 principal;        // Growing principal from staking + auctions
    uint256 pendingXen;      // XEN waiting to be staked
    uint256 lastStakeTime;   // Last XEN.network stake time
    uint256 stakeEndTime;    // When current XEN.network stake ends
    bool isStaking;          // Currently staking on XEN.network
    uint256 retryCount;      // Failed stake attempt counter
    uint256 totalAuctionXen; // Total XEN received from auctions
}

// Update principal after each stake cycle
function endStake() external nonReentrant {
    require(vaultState.isStaking, "Not staking");
    require(
        block.timestamp >= vaultState.stakeEndTime,
        "Stake not ended"
    );
    
    // Get stake info from XEN.network
    (uint256 principal, uint256 yield) = xenStaking.getStakeInfo(address(this));
    
    // Add accumulated auction XEN to principal
    vaultState.principal = principal.add(vaultState.totalAuctionXen);
    vaultState.totalAuctionXen = 0;
    
    // Burn yield
    if (yield > 0) {
        require(
            xenContract.transfer(burnAddress, yield),
            "Yield burn failed"
        );
        emit YieldBurned(yield, block.timestamp);
    }
    
    // Update vault state
    vaultState.isStaking = false;
    
    emit StakeEnded(vaultState.principal, yield);
}

// Receive XEN from auctions
function receiveXen(uint256 amount) external {
    require(msg.sender == address(auctionContract), "Only auction");
    require(
        xenContract.transferFrom(msg.sender, address(this), amount),
        "Transfer failed"
    );
    
    vaultState.pendingXen = vaultState.pendingXen.add(amount);
    vaultState.totalAuctionXen = vaultState.totalAuctionXen.add(amount);
    emit XenReceived(amount, block.timestamp);
}