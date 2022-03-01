// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { utils } = require('ethers');
const { ethers, upgrades } = require('hardhat')
const hre = require("hardhat");

require('dotenv').config()

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const TestFraktalERC20 = await hre.ethers.getContractFactory("TestFraktalERC20");
  const LooksRareAirdrop = await hre.ethers.getContractFactory("LooksRareAirdrop");
  const FraktalMarket = await hre.ethers.getContractFactory("FraktalMarket");

  const testFrak = await TestFraktalERC20.deploy();
  await testFrak.deployed();
  console.log("TestFrak deployed: ",testFrak.address);


  const fraktalMarket = await upgrades.deployProxy(FraktalMarket,[]);//deploy by proxy(upgradable)
  await fraktalMarket.deployed();
  console.log("Market deployed: ",fraktalMarket.address);

  const looksRareAirdrop = await LooksRareAirdrop.deploy(
      1648331266,
      utils.parseEther("10000"),
      testFrak.address,
      fraktalMarket.address
      );
  await looksRareAirdrop.deployed();
  console.log("Airdrop contract deployed: ",looksRareAirdrop.address);


//   console.log("Wait 1 min for etherscan to propagate deployed bytecode");
//   await new Promise(r=>setTimeout(r,60*1000));//wait 1 min
//   console.log("Verifying..");

//   await hre.run("verify:verify", {
//     address: testFrak.address,
//     constructorArguments: [],
//     contract: "contracts/TestFraktalERC20.sol:TestFraktalERC20"
//   });

//   await hre.run("verify:verify", {
//     address: fraktalMarket.address,
//     constructorArguments: [],
//   });

//   await hre.run("verify:verify", {
//     address: looksRareAirdrop.address,
//     constructorArguments: [
//         1648331266,
//         utils.parseEther("10000"),
//         testFrak.address,
//         fraktalMarket.address
//     ],
//   });

//   await greeter.deployed();

//   console.log("Greeter deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//   ·------------------------------|-------------|---------------·
//   TestFrak deployed:  0xf8FafAA9f045DbE9bb2045C0c5a6E769c156a531
//   Market deployed:  0x982CF2c4A790841A877E5E6EE880Da2566dAf02F
//   Airdrop contract deployed:  0x67a6335543b4295aA7D8165B3Cf906c7F36bcDFe