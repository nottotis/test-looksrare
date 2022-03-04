// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

import {TokenDistributor} from "./TokenDistributor.sol";

contract FeeSharingSystem is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    uint256 public constant PRECISION_FACTOR = 10**18;
    IERC20Upgradeable public  fraktalToken;
    uint256 public currentRewardPerBlock;
    uint256 public lastRewardAdjustment;
    uint256 public lastUpdateBlock;
    mapping(uint256=>uint256) public periodEndBlock;
    uint256 public rewardPerTokenStored;
    uint256 public totalShares;

    mapping(uint256=>uint256) public rewardOnRound;
    uint256 public roundNumber;
    uint256 public startBlock;
    uint256 public rewardDurationInBlocks;

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(uint256 numberBlocks, uint256 rewardPerBlock, uint256 reward);
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    // constructor(
    //     address _fraktalToken,
    //     uint256 _rewardDurationInBlocks,
    //     uint256 _startBlock
    // ) {
    //     fraktalToken = IERC20(_fraktalToken);
    //     rewardDurationInBlocks = _rewardDurationInBlocks;
    //     startBlock = _startBlock;
    // }

    function initialize(
        address _fraktalToken,
        uint256 _rewardDurationInBlocks,
        uint256 _startBlock
    ) public initializer {
        __Ownable_init();
        fraktalToken = IERC20Upgradeable(_fraktalToken);
        rewardDurationInBlocks = _rewardDurationInBlocks;
        startBlock = _startBlock;
    }

    function deposit(uint256 amount, bool claimRewardToken) external nonReentrant {
        require(amount >= PRECISION_FACTOR, "Deposit: Amount must be >= 1 LOOKS");


        // Update reward for user
        _updateReward(msg.sender);

        // Transfer LOOKS tokens to this address
        fraktalToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        if (totalShares != 0) {
            currentShares = amount;
            require(currentShares != 0, "Deposit: Fail");
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[msg.sender].shares += currentShares;
        totalShares += currentShares;

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;

                (bool sent,) = msg.sender.call{value: pendingRewards}("");
                require(sent, "Failed to send Ether");
                // rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        emit Deposit(msg.sender, amount, pendingRewards);
    }
    function harvest() external nonReentrant {

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        // If pending rewards are null, revert
        require(pendingRewards > 0, "Harvest: Pending rewards must be > 0");

        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        (bool sent,) = msg.sender.call{value: pendingRewards}("");
        require(sent, "Failed to send Ether");

        emit Harvest(msg.sender, pendingRewards);
    }

    function withdraw(uint256 shares, bool claimRewardToken) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender].shares),
            "Withdraw: Shares equal to 0 or larger than user shares"
        );

        _withdraw(shares, claimRewardToken);
    }

    function withdrawAll(bool claimRewardToken) external nonReentrant {
        _withdraw(userInfo[msg.sender].shares, claimRewardToken);
    }

    function updateRewards() public {
        // Adjust the current reward per block
        if ((block.number > startBlock) && (block.number >= periodEndBlock[roundNumber]) ) {
            //console.log("Updating reward",rewardOnRound[roundNumber]);
            roundNumber++;
            uint256 reward = rewardOnRound[roundNumber]; 
            currentRewardPerBlock = reward / rewardDurationInBlocks;

            lastUpdateBlock = block.number;
            periodEndBlock[roundNumber] = block.number + rewardDurationInBlocks;

            emit NewRewardPeriod(rewardDurationInBlocks, currentRewardPerBlock, reward);
        } 
        // else {
        //     currentRewardPerBlock =
        //         (reward + ((periodEndBlock - block.number) * currentRewardPerBlock)) /
        //         rewardDurationInBlocks;
        // }
    }
    function calculatePendingRewards(address user) external view returns (uint256) {
        return _calculatePendingRewards(user);
    }

    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    function _calculatePendingRewards(address user) internal view returns (uint256) {
        //console.log("userInfo[user].shares:%s,_rewardPerToken() %s,userInfo[user].userRewardPerTokenPaid %s",userInfo[user].shares,_rewardPerToken(),userInfo[user].userRewardPerTokenPaid);

        return
            ((userInfo[user].shares * (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    function _lastRewardBlock() internal view returns (uint256) {
        return block.number <  periodEndBlock[roundNumber] ? block.number :  periodEndBlock[roundNumber];
    }

    function _rewardPerToken() internal view returns (uint256) {
        //console.log("TotalShare:",totalShares);
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }


        //console.log("rewardPerTokenStored:",rewardPerTokenStored);
        //console.log("currentRewardPerBlock:",currentRewardPerBlock);
        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    function _updateReward(address _user) internal {
        updateRewards();
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    function _withdraw(uint256 shares, bool claimRewardToken) internal {
        

        // Update reward for user
        _updateReward(msg.sender);

        userInfo[msg.sender].shares -= shares;
        totalShares -= shares;

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                (bool sent,) = msg.sender.call{value: pendingRewards}("");
                require(sent, "Failed to send Ether");
                // rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        // Transfer LOOKS tokens to sender
        uint256 currentAmount = shares;
        fraktalToken.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, pendingRewards);
    }

    function currentRewardPool() external view returns(uint256){
        return rewardOnRound[roundNumber];
    }

    function currentEndBlock() external view returns(uint256){
        return periodEndBlock[roundNumber];
    }

    //for emergency by Gnosis Multisig
    function withdraw() external onlyOwner{
        uint256 currentBalance = address(this).balance;
        (bool sent,) = msg.sender.call{value: currentBalance}("");
        require(sent, "Failed to send Ether");
    }

    //for emergency by Gnosis Multisig
    function withdrawToken(address tokenAddress) external onlyOwner{
        uint256 currentBalance = IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        IERC20Upgradeable(tokenAddress).safeTransfer(msg.sender, currentBalance);
    }

    receive() external payable {
        require(block.number>=startBlock,"Pool does not start yet");
        rewardOnRound[roundNumber+1] += msg.value;
        updateRewards();
    }
}