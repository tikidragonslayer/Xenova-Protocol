// Calculate stake weight for penalty distribution
    function _calculateStakeWeight(
        StakeInfo storage stake
    ) internal view returns (uint256) {
        // Weight based on amount and duration
        uint256 durationWeight;
        if(stake.duration >= 365 days) {
            durationWeight = 60; // 60% for 365-day stakes
        } else if(stake.duration >= 180 days) {
            durationWeight = 25; // 25% for 180-day stakes
        } else if(stake.duration >= 90 days) {
            durationWeight = 15; // 15% for 90-day stakes
        } else {
            durationWeight = 5;  // 5% base weight for minimum stakes
        }

        // Weight = stake amount * duration weight
        return stake.amount.mul(durationWeight);
    }