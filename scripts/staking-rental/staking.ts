// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv";
import { defender, ethers, upgrades } from "hardhat";
dotenv.config();

async function main() {
  let staking: any;
  const proxyAddress = null;
  const PURPOSE_REQ = false;

  const nft = "0xa22a01abe48738ebace493e4a2cc2111b72f96c1";
  const baseURI = "https://api.netvrk.co/api/bonus-pack/";

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      const NFTStaking = await ethers.getContractFactory("NFTStaking");
      const proposal = await defender.proposeUpgrade(proxyAddress, NFTStaking, {
        multisig: process.env.MULTI_SIG,
        title: "Upgrade staking contract #1",
        description: "Upgrade with some new changes",
      });
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      const NFTStaking = await ethers.getContractFactory("NFTStaking");
      staking = await upgrades.upgradeProxy(proxyAddress, NFTStaking);
      await staking.deployed();
    }
  } else {
    const NFTStaking = await ethers.getContractFactory("StakedNetvrkBonus");
    staking = await upgrades.deployProxy(NFTStaking, [nft, baseURI], {
      kind: "uups",
    });

    await staking.deployed();
  }

  console.log("NFTStaking deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
