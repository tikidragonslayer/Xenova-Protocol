// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IXenovaSprinkler {
    function receiveFees() external payable;
    function distributeFees(address[] calldata winners) external;
    function selectWinners() external view returns (address[] memory);
    
    event FeesReceived(uint256 amount, uint256 timestamp);
    event FeesDistributed(address[] winners, uint256[] amounts);
}