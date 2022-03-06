const { expect } = require("chai");
const { utils, BigNumber } = require("ethers");
const { ethers, network } = require("hardhat");

const mineBlock = async (numBlock) => {
  for(i=0;i<numBlock;i++){
      await network.provider.send("evm_mine")
  }
}



describe("FeeSharingSystem", function () {
  it("Should return harvest(ETH not WETH) according to staked users", async function () {
    const [owner,alice,bob] = await ethers.getSigners();

    
    

    const TestFraktalERC20 = await hre.ethers.getContractFactory("TestFraktalERC20");
    const frakToken = await TestFraktalERC20.deploy();
    await frakToken.deployed();
    const rewardToken = await TestFraktalERC20.deploy();
    await rewardToken.deployed();

    await frakToken.transfer(alice.address,utils.parseEther("10000"));
    await frakToken.transfer(bob.address,utils.parseEther("10000"));

    const StakingRewards = await hre.ethers.getContractFactory("StakingRewards");
    const stakingRewards = await StakingRewards.deploy(frakToken.address,500);
    await stakingRewards.deployed();

    

    console.log("stakingRewards deployed to:", stakingRewards.address, await ethers.provider.getBalance(stakingRewards.address));

    //for debugging
    const showFeeSystemData = async () =>{
      const currentBlock = (await ethers.provider.getBlock("latest")).number;
      const currentRound = (await stakingRewards.roundNumber()).toNumber();
      const roundInfo = await stakingRewards.roundInfo(currentRound);
      const lastUpdateBlock = await stakingRewards.lastUpdateBlock();
      console.log(`Current block: ${currentBlock}, round:${currentRound}, lastUpdate: ${lastUpdateBlock}`);
    }

    //alice approve tokens to feeSharingSystem
    await frakToken.connect(alice).approve(stakingRewards.address,utils.parseEther("10000"));
    // await frakToken.connect(bob).approve(feeSharingSystem.address,utils.parseEther("100000"));

    //give feeSharingSystem some ETH(simulate marketplace fee collected)
    await owner.sendTransaction({
      to:stakingRewards.address,
      value:utils.parseEther("1")
    })
    console.log("Sent fees");

    await stakingRewards.connect(alice).stake(utils.parseEther("100"));
    console.log("Alice deposit");
    await showFeeSystemData();

    await mineBlock(497);
    await stakingRewards.connect(alice).getReward();

    console.log("Alice balance:",await ethers.provider.getBalance(alice.address));


    
  });
});
  