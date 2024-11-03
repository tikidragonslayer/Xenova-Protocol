// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IXenovaBurnCredits {
    function updateStake(address holder, uint256 amount, bool isStaking) external;
    function distributeCredits(uint256 xenBurned) external;
    function getStakeInfo(address holder) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 lastAccrual,
        uint256 pendingCredits
    );
    
    event CreditsAccrued(address indexed holder, uint256 amount, uint256 timestamp);
    event StakeUpdated(address indexed holder, uint256 amount, uint256 startTime);
    event XenBurned(uint256 amount, uint256 timestamp);
}