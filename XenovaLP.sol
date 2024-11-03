// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IXenovaSprinkler.sol";

contract XenovaLP is ReentrancyGuard {
    using SafeMath for uint256;

    // LP Schedule
    uint256 public constant LP_CREATION_INTERVAL = 14 days; // Bi-weekly
    uint256 public constant LP_CREATION_WINDOW = 2 days; // Weekend window
    uint256 public constant FEE_COLLECTION_INTERVAL = 60 days;
    uint256 public lastLPCreation;
    uint256 public lastFeeCollection;
    uint256 public accumulatedETH;

    // LP Position tracking
    struct LPPosition {
        uint256 tokenId;
        uint256 creationTime;
        bool active;
        uint256 lastFeeCollection;
    }

    LPPosition[] public lpPositions;
    mapping(uint256 => uint256) public positionIndex; // tokenId => index
    
    // Dependencies
    IXenovaSprinkler public immutable sprinkler;
    
    // Events
    event LPCreated(uint256 indexed tokenId, uint256 ethAmount, uint256 xenovaAmount);
    event FeesCollected(uint256 indexed tokenId, uint256 amount, uint256 timestamp);
    event FeesDistributed(uint256 totalAmount, uint256 timestamp);
    event LPTokenBurned(uint256 indexed tokenId);

    constructor(address _sprinkler) {
        sprinkler = IXenovaSprinkler(_sprinkler);
        lastFeeCollection = block.timestamp;
    }

    // Create new LP position
    function createLPPosition() external nonReentrant {
        require(
            block.timestamp >= lastLPCreation + LP_CREATION_INTERVAL,
            "Too early for LP creation"
        );
        
        // Verify it's weekend window
        uint256 dayOfWeek = (block.timestamp / 1 days + 4) % 7;
        require(
            dayOfWeek == 0 || dayOfWeek == 6,
            "LP creation only on weekends"
        );

        require(accumulatedETH > 0, "No ETH accumulated");

        // Create Uniswap V3 position
        (uint256 tokenId, uint256 ethUsed, uint256 xenovaAmount) = 
            _createUniswapPosition(accumulatedETH);

        // Store position info
        lpPositions.push(LPPosition({
            tokenId: tokenId,
            creationTime: block.timestamp,
            active: true,
            lastFeeCollection: block.timestamp
        }));
        positionIndex[tokenId] = lpPositions.length - 1;

        // Burn LP token
        _burnLPToken(tokenId);

        // Reset accumulated ETH
        accumulatedETH = 0;
        lastLPCreation = block.timestamp;

        emit LPCreated(tokenId, ethUsed, xenovaAmount);
        emit LPTokenBurned(tokenId);
    }

    // Collect fees from all positions
    function collectAllFees() external nonReentrant {
        require(
            block.timestamp >= lastFeeCollection + FEE_COLLECTION_INTERVAL,
            "Too early for fee collection"
        );

        uint256 totalFees = 0;
        
        for(uint256 i = 0; i < lpPositions.length; i++) {
            LPPosition storage position = lpPositions[i];
            if (!position.active) continue;

            // Collect fees from position
            uint256 fees = _collectPositionFees(position.tokenId);
            if (fees > 0) {
                totalFees = totalFees.add(fees);
                position.lastFeeCollection = block.timestamp;
                emit FeesCollected(position.tokenId, fees, block.timestamp);
            }
        }

        // Send collected fees to sprinkler
        if (totalFees > 0) {
            sprinkler.receiveFees{value: totalFees}();
            emit FeesDistributed(totalFees, block.timestamp);
        }

        lastFeeCollection = block.timestamp;
    }

    // Internal function to collect fees from a single position
    function _collectPositionFees(
        uint256 tokenId
    ) internal returns (uint256) {
        // Get fee amounts
        (uint256 fee0, uint256 fee1) = IUniswapV3Pool(pool).collect(
            tokenId,
            address(this),
            type(uint128).max,
            type(uint128).max
        );

        // Convert token1 (XENOVA) fees to ETH if needed
        uint256 totalFees = fee0;
        if (fee1 > 0) {
            totalFees = totalFees.add(_convertXenovaToEth(fee1));
        }

        return totalFees;
    }

    // Internal function to burn LP token
    function _burnLPToken(uint256 tokenId) internal {
        // Transfer to burn address
        IUniswapV3Pool(pool).safeTransferFrom(
            address(this),
            burnAddress,
            tokenId
        );
    }

    // View functions
    function getLPInfo() external view returns (
        uint256 totalPositions,
        uint256 activeLPs,
        uint256 nextFeeCollection,
        uint256 accumulatedFees
    ) {
        uint256 active = 0;
        uint256 fees = 0;

        for(uint256 i = 0; i < lpPositions.length; i++) {
            if (lpPositions[i].active) {
                active++;
                fees = fees.add(_getUncollectedFees(lpPositions[i].tokenId));
            }
        }

        return (
            lpPositions.length,
            active,
            lastFeeCollection + FEE_COLLECTION_INTERVAL,
            fees
        );
    }

    // Get uncollected fees for a position
    function _getUncollectedFees(
        uint256 tokenId
    ) internal view returns (uint256) {
        (uint256 fee0, uint256 fee1) = IUniswapV3Pool(pool).fees(tokenId);
        
        // Estimate ETH value of fees
        uint256 totalFees = fee0;
        if (fee1 > 0) {
            totalFees = totalFees.add(_estimateXenovaToEth(fee1));
        }

        return totalFees;
    }

    receive() external payable {
        accumulatedETH = accumulatedETH.add(msg.value);
    }
}