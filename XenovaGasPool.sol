// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XenovaGasPool is ReentrancyGuard {
    using SafeMath for uint256;

    // Gas limits per operation
    struct OperationLimits {
        uint256 baseGasLimit;   // Base gas units required
        uint256 cooldown;       // Time between operations
        uint256 dailyLimit;     // Max operations per day
        uint256 batchSize;      // Max batch size
        uint256 maxGasPrice;    // Maximum gwei willing to pay (dynamic)
    }

    // Operation tracking
    struct OperationStats {
        uint256 lastCall;      // Last operation timestamp
        uint256 dailyCount;    // Operations today
        uint256 dailyReset;    // When daily count resets
    }

    // Gas price tracking
    struct GasPrice {
        uint256 price;         // Current gas price in gwei
        uint256 lastUpdate;    // Last update timestamp
        uint256 movingAvg;     // 24h moving average
    }

    // Gas pool state
    uint256 public totalCollected;
    uint256 public totalUsed;
    uint256 public constant CRITICAL_THRESHOLD = 0.05 ether;
    uint256 public constant MIN_RESERVE = 0.1 ether;
    uint256 public constant GAS_PRICE_UPDATE_INTERVAL = 1 hours;
    uint256 public constant MAX_GAS_PRICE_CHANGE = 50; // 50% max change

    GasPrice public gasPrice;
    
    // Operation limits
    mapping(bytes32 => OperationLimits) public operationLimits;
    mapping(bytes32 => mapping(address => OperationStats)) public operationStats;
    
    // Events
    event GasRequested(bytes32 indexed purpose, uint256 amount, uint256 gasPrice);
    event GasPriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 movingAvg);
    event LowGasWarning(uint256 remaining, uint256 required);
    event OperationDenied(bytes32 indexed purpose, string reason);

    constructor() {
        // Initialize with dynamic gas limits
        operationLimits["distribute"] = OperationLimits({
            baseGasLimit: 150000,
            cooldown: 1 hours,
            dailyLimit: 24,
            batchSize: 50,
            maxGasPrice: 0 // Will be set dynamically
        });
        
        operationLimits["claim"] = OperationLimits({
            baseGasLimit: 80000,
            cooldown: 1 hours,
            dailyLimit: 100,
            batchSize: 1,
            maxGasPrice: 0
        });
        
        operationLimits["burnCredits"] = OperationLimits({
            baseGasLimit: 120000,
            cooldown: 1 hours,
            dailyLimit: 24,
            batchSize: 100,
            maxGasPrice: 0
        });
        
        operationLimits["createLP"] = OperationLimits({
            baseGasLimit: 500000,
            cooldown: 14 days,
            dailyLimit: 1,
            batchSize: 1,
            maxGasPrice: 0
        });

        // Initialize gas price tracking
        gasPrice = GasPrice({
            price: tx.gasprice,
            lastUpdate: block.timestamp,
            movingAvg: tx.gasprice
        });
    }

    // Update gas price based on network conditions
    function _updateGasPrice() internal {
        if (block.timestamp < gasPrice.lastUpdate + GAS_PRICE_UPDATE_INTERVAL) {
            return;
        }

        uint256 oldPrice = gasPrice.price;
        uint256 newPrice = tx.gasprice;
        
        // Calculate moving average
        gasPrice.movingAvg = (gasPrice.movingAvg * 23 + newPrice) / 24;
        
        // Limit price change to prevent extreme swings
        uint256 maxChange = oldPrice.mul(MAX_GAS_PRICE_CHANGE).div(100);
        if (newPrice > oldPrice.add(maxChange)) {
            newPrice = oldPrice.add(maxChange);
        } else if (newPrice < oldPrice.sub(maxChange)) {
            newPrice = oldPrice.sub(maxChange);
        }

        gasPrice.price = newPrice;
        gasPrice.lastUpdate = block.timestamp;

        // Update operation limits based on new gas price
        _updateOperationLimits(newPrice);
        
        emit GasPriceUpdated(oldPrice, newPrice, gasPrice.movingAvg);
    }

    // Update operation gas limits based on current price
    function _updateOperationLimits(uint256 newGasPrice) internal {
        bytes32[4] memory ops = [
            bytes32("distribute"),
            bytes32("claim"),
            bytes32("burnCredits"),
            bytes32("createLP")
        ];

        for(uint256 i = 0; i < ops.length; i++) {
            OperationLimits storage limit = operationLimits[ops[i]];
            
            // Set max gas price relative to moving average
            limit.maxGasPrice = gasPrice.movingAvg.mul(150).div(100); // 50% above moving avg
        }
    }

    // Request gas with dynamic pricing
    function requestGas(
        bytes32 purpose,
        uint256 batchSize,
        address caller
    ) external nonReentrant returns (uint256) {
        require(authorizedContracts[msg.sender], "Unauthorized");
        require(batchSize > 0, "Invalid batch size");

        // Update gas price first
        _updateGasPrice();

        OperationLimits memory limits = operationLimits[purpose];
        OperationStats storage stats = operationStats[purpose][caller];

        // Validate operation
        require(
            batchSize <= limits.batchSize,
            "Batch size exceeds limit"
        );

        // Check if current gas price is acceptable
        require(
            tx.gasprice <= limits.maxGasPrice,
            "Gas price too high"
        );

        // Calculate required gas
        uint256 gasRequired = limits.baseGasLimit.mul(batchSize);
        uint256 gasCost = gasRequired.mul(tx.gasprice);
        
        // Ensure sufficient reserve
        require(
            address(this).balance >= gasCost.add(MIN_RESERVE),
            "Insufficient gas"
        );

        // Update stats
        stats.lastCall = block.timestamp;
        stats.dailyCount++;
        totalUsed = totalUsed.add(gasCost);

        // Transfer gas
        (bool success,) = caller.call{value: gasCost}("");
        require(success, "Gas transfer failed");

        emit GasRequested(purpose, gasCost, tx.gasprice);
        
        // Check remaining gas
        if (address(this).balance < CRITICAL_THRESHOLD) {
            emit LowGasWarning(address(this).balance, MIN_RESERVE);
        }

        return gasCost;
    }

    // View functions
    function getOperationCost(
        bytes32 purpose,
        uint256 batchSize
    ) external view returns (
        uint256 estimatedCost,
        uint256 maxAcceptablePrice
    ) {
        OperationLimits memory limits = operationLimits[purpose];
        uint256 gasRequired = limits.baseGasLimit.mul(batchSize);
        
        return (
            gasRequired.mul(gasPrice.price),
            limits.maxGasPrice
        );
    }

    // Receive ETH from tax collection
    receive() external payable {
        require(
            msg.sender == address(coreContract) ||
            msg.sender == address(auctionContract),
            "Unauthorized"
        );
        totalCollected = totalCollected.add(msg.value);
    }
}