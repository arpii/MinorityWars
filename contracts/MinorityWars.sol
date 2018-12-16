pragma solidity ^0.4.25;

import "./ContractUtility.sol";

contract MinorityWars is ContractUtility{
    function move(uint32 landId) external validLandId(landId) movingFeeCharge notDictator gameContinue payable {
        Player storage player = playerMap[msg.sender];

        if (_onLeastPopulationLand(landId)) {
            player.experience = player.experience.add(1);
        }

        // delete previous land population
        if (player.location != emptyId) {
            landMap[player.location].population = landMap[player.location].population.sub(1);
            landMap[player.location].timeStamp = now;
            landMap[player.location].totalContribution = landMap[player.location].totalContribution.sub(player.contribution);
        }

        // pay dividend to dictator
        address dictator = landMap[landId].dictator;
        if (dictator != address(0)) {
            playerMap[dictator].vault = playerMap[dictator].vault.add(moveLandDividend);
            playerMap[dictator].totalGains = playerMap[dictator].totalGains.add(moveLandDividend);
            totalBonus = totalBonus.add(moveFee).sub(moveLandDividend);
        }
        else {
            totalBonus = totalBonus.add(moveFee);
        }

        // move to new land
        landMap[landId].population = landMap[landId].population.add(1);
        landMap[player.location].timeStamp = now + 1;
        player.location = landId;
        player.contribution = player.contribution.add(moveFee);
        landMap[player.location].totalContribution = landMap[player.location].totalContribution.add(player.contribution);
        emit PlayerMove(msg.sender, landId);
    }

    function buy(uint32 landId) external validLandId(landId) affortable(landId) smartEnough gameContinue payable {
        Player storage player = playerMap[msg.sender];
        Land storage land = landMap[landId];

        // delete previous land population
        player.experience = 0;
        landMap[player.location].population = landMap[player.location].population.sub(1);
        landMap[player.location].timeStamp = now;
        landMap[player.location].totalContribution = landMap[player.location].totalContribution.sub(player.contribution);

        // pay dividend to dictator
        address dictator = land.dictator;
        if (dictator != address(0)) {
            uint dividend = land.dictatorPrice.mul(buyDictatorDividendRatio).div(100);
            playerMap[dictator].vault = playerMap[dictator].vault.add(dividend);
            playerMap[dictator].totalGains = playerMap[dictator].totalGains.add(dividend);

            playerMap[dictator].isDictator = false;
            totalBonus = totalBonus.add(land.dictatorPrice).sub(dividend);
        }
        else {
            totalBonus = totalBonus.add(land.dictatorPrice);
        }

        // be a dictator
        landMap[landId].population = landMap[landId].population.add(1);
        landMap[player.location].timeStamp = now + 1;
        player.location = landId;
        player.contribution = player.contribution.add(land.dictatorPrice);
        landMap[player.location].totalContribution = landMap[player.location].totalContribution.add(player.contribution);

        land.dictator = msg.sender;
        player.isDictator = true;
        emit PlayerBuy(msg.sender, landId, land.dictatorPrice);
        land.dictatorPrice = land.dictatorPrice.add(dictatorPriceIncrement);
    }

    function addSlogan(string slogan) external onlyDictator {
        landMap[playerMap[msg.sender].location].slogan = slogan;
    }

    function withdraw() external {
        Player storage player = playerMap[msg.sender];

        if (now >= endGameTime) {
            gameIsTerminated = true;
        }

        if (gameIsTerminated && !player.alreadyWithdraw) {
            uint32 winningLand = _getLeastPopulationLand();
            if (player.location == winningLand) {
                if (player.isDictator) {
                    uint dictatorDividend = totalBonus.mul(dictatorSharesRatio).div(100);
                    player.vault = player.vault.add(dictatorDividend);
                    player.totalGains = player.totalGains.add(dictatorDividend);
                }

                uint bonusPerContribution = totalBonus.mul(citizenSharesRatio).div(100).div(landMap[winningLand].totalContribution);
                uint dividend = bonusPerContribution.mul(player.contribution);
                player.vault = player.vault.add(dividend);
                player.totalGains = player.totalGains.add(dividend);
            }
            player.alreadyWithdraw = true;
        }

        msg.sender.transfer(player.vault);
        player.vault = 0;
    }

    function ownerWithdraw() external onlyOwner {
        if (now >= endGameTime) {
            gameIsTerminated = true;
        }

        if(gameIsTerminated && ownerIsPaid == false) {
            ownerIsPaid = true;
            msg.sender.transfer(totalBonus.mul(ownerSharesRatio).div(100));
        }
    }

    function _onLeastPopulationLand(uint32 landId) internal view returns(bool){
        uint32 i = 0;
        uint32 minimum = 4294967295;
        for(i = 1; i <= landCount; i++) {
            if (landMap[i].population < minimum) {
                minimum = landMap[i].population;
            }
        }
        if (landMap[landId].population == minimum)
            return true;
        else
            return false;
    }

    function _getLeastPopulationLand() internal view returns(uint32){
        uint32 i = 0;
        uint32 minimumPopulation = 4294967295;
        uint minimumTimeStamp = 0;
        uint32 landId = 0;
        for(i = 1; i <= landCount; i++) {
            if (landMap[i].population < minimumPopulation) {
                minimumPopulation = landMap[i].population;
            }
        }
        for(i = 1; i <= landCount; i++) {
            if (landMap[i].population == minimumPopulation && (minimumTimeStamp == 0 || landMap[i].timeStamp <= minimumTimeStamp)) {
                minimumTimeStamp = landMap[i].timeStamp;
                landId = i;
            }
        }
        return landId;
    }
}
