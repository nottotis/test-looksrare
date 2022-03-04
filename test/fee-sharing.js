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

    const FeeSharingSystem = await hre.ethers.getContractFactory("FeeSharingSystem");
    const feeSharingSystem = await upgrades.deployProxy(FeeSharingSystem,[frakToken.address,500,10]);
    await feeSharingSystem.deployed();

    

    console.log("FeeSharingSystem deployed to:", feeSharingSystem.address, await ethers.provider.getBalance(feeSharingSystem.address));

    //for debugging
    const showFeeSystemData = async () =>{
      const currentBlock = (await ethers.provider.getBlock("latest")).number;
      const currentRewardPool = await feeSharingSystem.currentRewardPool();
      const currentRound = (await feeSharingSystem.roundNumber()).toNumber();
      const currentEndBlock = await feeSharingSystem.currentEndBlock();
      const lastUpdateBlock = await feeSharingSystem.lastUpdateBlock();
      console.log(`Current block: ${currentBlock}, pool:${currentRewardPool}, round:${currentRound}, endBlock:${currentEndBlock}, lastUpdate: ${lastUpdateBlock}`);
    }

    //alice approve tokens to feeSharingSystem
    await frakToken.connect(alice).approve(feeSharingSystem.address,utils.parseEther("10000"));
    // await frakToken.connect(bob).approve(feeSharingSystem.address,utils.parseEther("100000"));

    //give feeSharingSystem some ETH(simulate marketplace fee collected)
    await owner.sendTransaction({
      to:feeSharingSystem.address,
      value:utils.parseEther("1")
    })

    console.log("Sending fees");
    await showFeeSystemData();
    await feeSharingSystem.connect(alice).deposit(utils.parseEther("100"),false);
    console.log("Alice deposit");
    await showFeeSystemData();
    await feeSharingSystem.connect(alice).deposit(utils.parseEther("1"),false);
    console.log("Alice staked");
    await showFeeSystemData();
    await mineBlock(497);//alice pending reward +/- 1 eth, this is good
    // await mineBlock(498);//alice pending reward became 0.2 eth, even though she staked for full period, this is bad
    await feeSharingSystem.connect(alice).withdrawAll(false);
    console.log("Alice stake");
    await showFeeSystemData();
    console.log("Alice pending rewards:",await feeSharingSystem.calculatePendingRewards(alice.address));
    await showFeeSystemData();


    
  });
});
  