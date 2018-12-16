pragma solidity ^0.4.25;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMath32.sol";

contract ContractUtility is Ownable {
    using SafeMath32 for uint32;
    using SafeMath for uint;

    mapping (address => Player) public playerMap;
    mapping (uint32 => Land) public landMap;

    // init
    uint32 public landCount = 10;
    uint32 public emptyId = 0;

    // buy dictator
    uint32 public expThreshold = 3;
    uint32 public buyDictatorDividendRatio = 40;

    // gameover calculation
    uint32 public dictatorSharesRatio = 20;
    uint32 public citizenSharesRatio = 70;
    uint32 public ownerSharesRatio = 10;

    bool public gameIsTerminated = false;
    bool public ownerIsPaid = false;
    uint public endGameTime = 1544976000000;  // 2018.12.17 00:00:00 micro second

    // fee, price
    uint public moveFee = 20 finney;
    uint public moveLandDividend = 12 finney;  // moveFee * 60 %
    uint public dictatorPriceIncrement = 10 finney;
    uint public addSloganFee = 20 finney;

    uint public totalBonus = 0;

    struct Player {
        uint contribution;
        uint totalGains;
        uint vault;
        uint32 experience;
        uint32 location;
        bool isDictator;
        bool alreadyWithdraw;
    }

    struct Land {
        uint totalContribution;
        uint dictatorPrice;
        address dictator;
        uint32 population;
        string slogan;
        uint timeStamp;
    }

    event PlayerMove(
        address indexed playerAddress,
        uint32 landId
    );

    event PlayerBuy(
        address indexed playerAddress,
        uint32 landId,
        uint dictatorPrice
    );

    modifier movingFeeCharge() {
        require(msg.value >= moveFee, "Not enough moveFee");
        _;
    }

    modifier validLandId(uint32 landId) {
        require(landId > emptyId && landId <= landCount, "Invalid landId");
        _;
    }

    modifier notDictator() {
        require(playerMap[msg.sender].isDictator == false, "Dictator cannot move");
        _;
    }

    modifier onlyDictator() {
        require(playerMap[msg.sender].isDictator == true, "Only dictator can call this.");
        _;
    }

    modifier affortable(uint32 landId) {
        require(msg.value >= landMap[landId].dictatorPrice, "You don't have enough money.");
        _;
    }

    modifier smartEnough() {
        require(playerMap[msg.sender].experience >= expThreshold, "You don't have enough exp.");
        _;
    }

    modifier gameContinue() {
        require(now < endGameTime);
        _;
    }
}
