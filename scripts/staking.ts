// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
dotenv.config();

async function main() {
  const nft = "0x615b674216EB522E2dA4eE4dfbE9FFa04607062f";
  const baseURI = "https://example.com/transport";
  let staking = null;

  const NFTStaking = await ethers.getContractFactory("NFTStaking");
  staking = await upgrades.deployProxy(NFTStaking, [nft, baseURI], {
    kind: "uups",
  });

  await staking.deployed();

  console.log("NFTStaking deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
