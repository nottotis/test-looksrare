// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [premintReceiver] = await ethers.getSigners();



  // We get the contract to deploy

  //need 3 argument
  //_premintReceiver address of team vault (Gnosis)
  //_premintAmount amount of LooksRareToken to be given to team address
  //_cap max number of token(total supply)
  const LooksRareToken = await hre.ethers.getContractFactory("LooksRareToken");

  //need 3 argument
  //_looksRareToken LooksRareToken address
  //_rewardToken WETH address
  //_tokenDistributor TokenDistributor contract address
  const FeeSharingSystem = await hre.ethers.getContractFactory("FeeSharingSystem");

  //need 7 arguments
  //_looksRareToken address of LooksRareToken
  //__tokenSplitter address of TokenSplitter
  //_startBlock start block
  //_rewardsPerBlockForStaking uint256 array of reward per block(staking) [189000000000000000000,89775000000000000000,35437500000000000000,18900000000000000000]
  //_rewardsPerBlockForOthers uint256 array of reward per block(others?) [611000000000000000000,290225000000000000000,114562500000000000000,61100000000000000000]
  //_periodLengthesInBlocks uint256 array of period length in block [195000,585000,1560000,2346250]
  //_numberPeriods number of period in uint256
  const TokenDistributor = await hre.ethers.getContractFactory("TokenDistributor");

  //need 3 arguments
  //addresses address array
  //shares uint256 array
  //token looksraretoken address
  const TokenSplitter = await hre.ethers.getContractFactory("TokenSplitter");

  const looksRareToken = await LooksRareToken.deploy(
      premintReceiver.address,
      BigNumber.from("200000000000000000000000000"),//200Million (20%)
      BigNumber.from("1000000000000000000000000000")//1Billion (100%)
      );

  await looksRareToken.deployed();

  console.log("looksRareToken deployed to:", looksRareToken.address);
  console.log("Premint val:",(await looksRareToken.balanceOf(premintReceiver.address)).toString())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
