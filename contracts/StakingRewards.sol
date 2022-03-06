// SPDX-License-Identifier: MIT
import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract StakingRewards {
    IERC20 public stakingToken;

    struct RoundInfo{
        uint startBlock;
        uint endBlock;
        uint rewardPerTokenStored;
        uint rewardRate;
        bool passed;
    }

    struct UserRewardPerTokenpaid{
        uint amount;
        uint blockNumber;
    }

    uint public roundNumber;
    uint public lastUpdateBlock;
    uint public rewardDurationInBlock;

    mapping(uint=>RoundInfo) public roundInfo;
    // mapping(uint=>uint) public rewardRate; //roundNumber => rewardRate
    // mapping(uint=>uint) public rewardPerTokenStored; //roundNumber => rewardPerTokenStored

    // mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => UserRewardPerTokenpaid) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint public _totalSupply;
    mapping(address => uint) public _balances;

    constructor(address _stakingToken, uint _rewardDurationInBlock) {
        stakingToken = IERC20(_stakingToken);
        // rewardsToken = IERC20(_rewardsToken);
        rewardDurationInBlock = _rewardDurationInBlock;
        updateRewards();
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return roundInfo[roundNumber].rewardPerTokenStored +
            (((block.number - lastUpdateBlock) * roundInfo[roundNumber].rewardRate * 1e18) / _totalSupply);

    }

    function earned(address account) public view returns (uint) {
        uint _earned;
        uint _userPaidBlockNumber = userRewardPerTokenPaid[account].blockNumber;
        uint _userPaidAmount =  userRewardPerTokenPaid[account].amount;
        uint _userPaidRound = getRound(_userPaidBlockNumber);

        console.log("%s < %s",_userPaidRound, roundNumber);

        while(_userPaidRound<roundNumber){
                _earned += ((_balances[account] * (roundInfo[_userPaidRound].rewardPerTokenStored - _userPaidAmount)) / 1e18) + rewards[account];
                _userPaidRound++;
        }
        console.log("earned:",_earned);


        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account].amount)) / 1e18) +
            rewards[account] + _earned;
    }

    modifier updateReward(address account) {
        updateRewards();
        roundInfo[roundNumber].rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account].amount = roundInfo[roundNumber].rewardPerTokenStored;
        userRewardPerTokenPaid[account].blockNumber = block.number;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        console.log(reward);
        rewards[msg.sender] = 0;
        // rewardsToken.transfer(msg.sender, reward);
        (bool sent,) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send Ether");
    }

    function getRound(uint _blockNumber) public view returns(uint) {
        uint _round = 0;
        while(_round <= roundNumber){
            if(_blockNumber < roundInfo[_round].endBlock){
                return _round;
            }
            _round++;
        }
        return 0;
    }

    function updateRewards() public {
        if(block.number > roundInfo[roundNumber].endBlock){
            roundInfo[roundNumber].passed = true;
            if(_totalSupply!=0){
                roundInfo[roundNumber].rewardPerTokenStored = roundInfo[roundNumber].rewardPerTokenStored + 
                (((roundInfo[roundNumber].endBlock - lastUpdateBlock) * roundInfo[roundNumber].rewardRate * 1e18) / _totalSupply);
            }

            roundNumber++;
            roundInfo[roundNumber].startBlock = block.number;
            roundInfo[roundNumber].endBlock = rewardDurationInBlock;
        }
    }

    receive() external payable{
        roundInfo[roundNumber].rewardRate += msg.value;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
