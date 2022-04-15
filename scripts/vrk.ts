import { ethers } from "hardhat";

async function main() {
  const VRK = await ethers.getContractFactory("VRK");

  const vrk = await VRK.deploy();

  await vrk.deployed();

  console.log("VRK deployed to:", vrk.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
