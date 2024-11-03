// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IXenovaLP {
    function updateLPRange(uint256 chainId) external;
    function createLPPosition(
        uint256 chainId,
        uint256 tokenAmount,
        uint256 nativeAmount
    ) external;
    function withdrawFees() external;
    function getLPRange(uint256 chainId) external view returns (
        uint256 lowerTick,
        uint256 upperTick,
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 lastUpdate
    );
    function getCurrentPriceInfo() external view returns (
        uint256 currentPrice,
        uint256 allTimeHigh,
        uint256 priceBuffer
    );
    
    event LPRangeUpdated(
        uint256 indexed chainId,
        uint256 lowerTick,
        uint256 upperTick,
        uint256 timestamp
    );
    event PriceUpdated(uint256 price, uint256 timestamp);
    event NewAllTimeHigh(uint256 price, uint256 timestamp);
    event FeesWithdrawn(uint256 amount, uint256 timestamp);
}