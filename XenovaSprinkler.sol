// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XenovaSprinkler is ReentrancyGuard {
    using SafeMath for uint256;

    // Constants
    uint256 public constant DISTRIBUTION_INTERVAL = 60 days;
    uint256 public constant WINNERS_PER_CYCLE = 3;
    uint256 public constant TOP_STAKERS_COUNT = 1000;
    
    // State
    uint256 public lastDistribution;
    uint256 public accumulatedFees;
    
    // Events
    event FeesReceived(uint256 amount, uint256 timestamp);
    event FeesDistributed(address[] winners, uint256[] amounts);
    event WinnersSelected(address[] winners, uint256 timestamp);

    // Receive fees from LP positions
    function receiveFees() external payable {
        require(msg.sender == address(lpContract), "Only LP contract");
        accumulatedFees = accumulatedFees.add(msg.value);
        emit FeesReceived(msg.value, block.timestamp);
    }

    // Distribute accumulated fees to winners
    function distributeFees() external nonReentrant {
        require(
            block.timestamp >= lastDistribution + DISTRIBUTION_INTERVAL,
            "Too early"
        );
        require(accumulatedFees > 0, "No fees to distribute");

        // Select winners
        address[] memory winners = selectWinners();
        require(winners.length > 0, "No eligible winners");

        // Calculate share per winner
        uint256 sharePerWinner = accumulatedFees.div(winners.length);
        uint256[] memory amounts = new uint256[](winners.length);

        // Distribute to winners
        for(uint256 i = 0; i < winners.length; i++) {
            amounts[i] = sharePerWinner;
            (bool success,) = winners[i].call{value: sharePerWinner}("");
            require(success, "Transfer failed");
        }

        // Reset state
        accumulatedFees = 0;
        lastDistribution = block.timestamp;

        emit FeesDistributed(winners, amounts);
    }

    // Select random winners from top stakers
    function selectWinners() public view returns (address[] memory) {
        address[] memory topStakers = stakingContract.getTopStakers(TOP_STAKERS_COUNT);
        require(topStakers.length > 0, "No eligible stakers");

        address[] memory winners = new address[](WINNERS_PER_CYCLE);
        uint256[] memory selected = new uint256[](topStakers.length);
        uint256 selectedCount = 0;

        // Use block properties for randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            block.number
        )));

        while(selectedCount < WINNERS_PER_CYCLE && selectedCount < topStakers.length) {
            seed = uint256(keccak256(abi.encodePacked(seed)));
            uint256 index = seed % topStakers.length;

            if (selected[index] == 0) {
                winners[selectedCount] = topStakers[index];
                selected[index] = 1;
                selectedCount++;
            }
        }

        return winners;
    }

    // View functions
    function getDistributionInfo() external view returns (
        uint256 nextDistribution,
        uint256 pendingFees,
        uint256 estimatedReward
    ) {
        address[] memory winners = selectWinners();
        uint256 estimatedShare = winners.length > 0 ? 
            accumulatedFees.div(winners.length) : 0;

        return (
            lastDistribution + DISTRIBUTION_INTERVAL,
            accumulatedFees,
            estimatedShare
        );
    }

    receive() external payable {
        revert("Use receiveFees()");
    }
}