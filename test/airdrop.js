const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs')

const SHA256 = require('crypto-js/sha256')

const leaves = ['a', 'b', 'c','a', 'b', 'c','a', 'b', 'c'].map(x => SHA256(x))
const tree = new MerkleTree(leaves, SHA256)

const root = tree.getRoot().toString('hex')
const leaf = SHA256('a')
const proof = tree.getProof(leaf)
// const root = "0x8dfab5f1445c86bab8ddecc22981110b60bb14aa0e326226e3974785643a4e57"
// const leaf = "0000000000000000000000009420a2c8eec2ba0342730914b85bc9ff6287a82d000000000000000000000000000000000000000000000084d0948357fb080000"
// const proof = [
//     "0x3b02c1f831fcb2d098ebc0350daf510115fa929ab51b22dc691e972cc14885de",
//     "0x35c1afd2e08c25d5f1da2e15c91d4ce75739f4123b7a806ca1cb4313fd559315",
//     "0x422c0099d85a4da472a2c59522311543c3a0de4e55a51202505c63b47c55b406",
//     "0xffd7161bec85a0e9df116a548b521380edfb135e5afc4e38bb5abcf9c3faa668",
//     "0xecfa690fbd0a1956ad4d0cf3e9256b68eb2df5313069ee4638184691418be744",
//     "0x940fa6bd3d20f830c0d48eea2f8935ca47067847e655b1d48236d5334894c7b1",
//     "0x43f7d01ab33c106e6a3abcd31f6adb69d982cc559b2aa554a0e61d7d77f9aa45",
//     "0xe5b8d173caf1dcd02cace546daf9d79846d05bb1702949d5c5598d486f98dddf",
//     "0x2e5342c474d2fcf68530421bf3cd68686e53b2dd407afa9e10edfc6c96ec66b9",
//     "0xfff8ee8840d77138a3cb85f79d85b0c91dfaee213f4d92a15e106401160d401b",
//     "0x7a099488643d2f4f9a1a78556da7d090282ff8cba353169872ad0a3a34a2c6d3",
//     "0x06d34a3f54166f5690a2f39bd1b2d1084fc1201d9c688cfa747699b7ab6a2ade",
//     "0x4568f10094e80e66bb7e8faf90287e4e43dbeff1be7c6a3fd76461dd39b9142c",
//     "0xbf17d686409a8f90a4d36dc58ef43134944128bf8deddf36b270c40905191a83",
//     "0x8839dac41a12be3f227d520d7e60c2d6d69dcccef9fceab28e7d5c0a5f2bbbff",
//     "0xe1fce32f1a895203014cd25029d4e73419bcd044ebf3ad7d8b6427b86dac46bb",
//     "0xfe50801a7bef2cb27394b8f38b989460324d5da324672374f3f56db21f02726c",
//     "0x21e1177887053e5b8b10967cb707cb04ff5d17a28b9973d7ea06b861303dbd5d"
//   ];

//   const buffer = Buffer.from(proof[0]);

console.log({tree, proof, leaf, root});
console.log(tree.verify(proof, leaf, root)) // true

// describe("Greeter", function () {
//     it("Should return the new greeting once it's changed", async function () {
//       const Greeter = await ethers.getContractFactory("Greeter");
//       const greeter = await Greeter.deploy("Hello, world!");
//       await greeter.deployed();
  
//       expect(await greeter.greet()).to.equal("Hello, world!");
  
//       const setGreetingTx = await greeter.setGreeting("Hola, mundo!");
  
//       // wait until the transaction is mined
//       await setGreetingTx.wait();
  
//       expect(await greeter.greet()).to.equal("Hola, mundo!");
//     });
//   });