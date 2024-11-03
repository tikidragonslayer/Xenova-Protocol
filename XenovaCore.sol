// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XenovaCore is ReentrancyGuard {
    using SafeMath for uint256;

    // Tax rates (5%)
    uint256 public constant BUY_TAX = 500;  // 5.00%
    uint256 public constant SELL_TAX = 500; // 5.00%
    uint256 public constant TAX_DENOMINATOR = 10000;

    // Tax distribution
    uint256 public constant STAKERS_TAX_SHARE = 75;   // 75% to stakers
    uint256 public constant LP_TAX_SHARE = 20;        // 20% to LP
    uint256 public constant GAS_TAX_SHARE = 5;        // 5% to gas fund

    // Track tax collections
    uint256 public totalTaxCollected;
    mapping(uint256 => uint256) public dailyTaxCollected;
    uint256 public currentDay;

    event TaxCollected(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 taxAmount,
        bool isBuy
    );

    // Calculate tax for a transfer
    function calculateTax(
        address from,
        address to,
        uint256 amount,
        bool isBuy
    ) public view returns (uint256) {
        uint256 taxRate = isBuy ? BUY_TAX : SELL_TAX;
        return amount.mul(taxRate).div(TAX_DENOMINATOR);
    }

    // Process transfer with tax
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        bool isBuy = to == address(lpContract);
        bool isSell = from == address(lpContract);

        uint256 taxAmount = 0;

        if (isBuy || isSell) {
            // Calculate and collect tax
            taxAmount = calculateTax(from, to, amount, isBuy);
            
            // Update tax tracking
            totalTaxCollected = totalTaxCollected.add(taxAmount);
            dailyTaxCollected[currentDay] = dailyTaxCollected[currentDay].add(taxAmount);

            // Distribute tax
            uint256 stakersShare = taxAmount.mul(STAKERS_TAX_SHARE).div(100);
            uint256 lpShare = taxAmount.mul(LP_TAX_SHARE).div(100);
            uint256 gasShare = taxAmount.mul(GAS_TAX_SHARE).div(100);

            // Send to staking contract
            _mint(address(stakingContract), stakersShare);
            stakingContract.distributeTaxRewards(stakersShare);

            // Send to LP
            _mint(address(lpContract), lpShare);
            lpContract.addTaxLiquidity(lpShare);

            // Send to gas fund
            _mint(address(gasPool), gasShare);

            emit TaxCollected(from, to, amount, taxAmount, isBuy);
        }

        // Transfer remaining amount
        uint256 transferAmount = amount.sub(taxAmount);
        super._transfer(from, to, transferAmount);
    }

    // View functions
    function getTaxInfo() external view returns (
        uint256 buyTaxRate,
        uint256 sellTaxRate,
        uint256 totalCollected,
        uint256 todayCollected
    ) {
        return (
            BUY_TAX,
            SELL_TAX,
            totalTaxCollected,
            dailyTaxCollected[currentDay]
        );
    }
}