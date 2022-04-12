// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  const nft = "0xF5B84B4F60F47616e79d7a46d43706B90AdD1e56";

  const NFTStaking = await ethers.getContractFactory("NFTStaking");
  const staking = await NFTStaking.deploy(nft);

  await staking.deployed();

  console.log("NFTStaking deployed to:", staking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
