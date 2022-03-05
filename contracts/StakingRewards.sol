// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    struct RoundInfo{
        uint startBlock;
        uint endBlock;
        uint rewardPerTokenStored;
        uint rewardRate;
    }

    struct UserRewardPerTokenpaid{
        uint amount;
        uint blockNumber;
    }

    uint public roundNumber;
    uint public lastUpdateBlock;

    mapping(uint=>RoundInfo) roundInfo;
    // mapping(uint=>uint) public rewardRate; //roundNumber => rewardRate
    // mapping(uint=>uint) public rewardPerTokenStored; //roundNumber => rewardPerTokenStored

    // mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => UserRewardPerTokenpaid) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function rewardPerToken(uint _roundNumber) public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        uint _endBlock = block.number > roundInfo[_roundNumber].endBlock ? roundInfo[_roundNumber].endBlock : block.number;
        return
            roundInfo[_roundNumber].rewardPerTokenStored +
            (((_endBlock - lastUpdateBlock) * roundInfo[_roundNumber].rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        uint _earned;
        uint _userPaidBlockNumber = userRewardPerTokenPaid[account].blockNumber;
        uint _userPaidAmount =  userRewardPerTokenPaid[account].amount;
        uint _userPaidRound = getRound(_userPaidBlockNumber);


        //if same periond
        if(roundNumber==_userPaidRound){
            return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
        }else{
            //if across multiple period
            while(_userPaidRound<=roundNumber){
                _earned += ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
            }
        }

        
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
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
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }

    function getRound(uint _blockNumber) public view returns(uint) {
        uint _roundNumber = roundNumber;
        while(_roundNumber>=0){
            if(block.number <= roundInfo[_roundNumber].endBlock){
                if(roundInfo[_roundNumber].startBlock < block.number){
                    return _roundNumber;
                }
            }
            _roundNumber--;
        }
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
