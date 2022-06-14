// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv";
import { defender, ethers, upgrades } from "hardhat";
dotenv.config();

async function main() {
  const proxyAddress = null;
  const PURPOSE_REQ = 0;
  const nft = "0xBCbEaE3620b3280dF67143Ad7eC45d67C5A4355e";
  const baseURI = "https://api.netvrk.co/api/bonus-pack/";

  let staking = null;

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      const StakedNetvrkBonus = await ethers.getContractFactory(
        "StakedNetvrkBonus"
      );
      const proposal = await defender.proposeUpgrade(
        proxyAddress,
        StakedNetvrkBonus,
        {
          multisig: process.env.MULTI_SIG,
          title: "Upgrade staking contract",
          description: "Upgrade with some changes",
        }
      );
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      const StakedNetvrkBonus = await ethers.getContractFactory(
        "StakedNetvrkBonus"
      );
      staking = await upgrades.upgradeProxy(proxyAddress, StakedNetvrkBonus);
      await staking.deployed();
    }
  } else {
    const StakedNetvrkBonus = await ethers.getContractFactory(
      "StakedNetvrkBonus"
    );
    staking = await upgrades.deployProxy(StakedNetvrkBonus, [nft, baseURI], {
      kind: "uups",
    });

    await staking.deployed();
  }

  console.log("StakedNetvrkBonus deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
