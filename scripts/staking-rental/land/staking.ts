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
  const nft = "0x244FC4178fa685Af909c88b4D4CD7eB9127eDb0B";
  const baseURI = "https://api.netvrk.co/api/items/";
  let staking = null;

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      const StakedNetvrkLand = await ethers.getContractFactory(
        "StakedNetvrkLand"
      );
      const proposal = await defender.proposeUpgrade(
        proxyAddress,
        StakedNetvrkLand,
        {
          multisig: process.env.MULTI_SIG,
          title: "Upgrade staking contract",
          description: "Upgrade with some changes",
        }
      );
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      const StakedNetvrkLand = await ethers.getContractFactory(
        "StakedNetvrkLand"
      );
      staking = await upgrades.upgradeProxy(proxyAddress, StakedNetvrkLand);
      await staking.deployed();
    }
  } else {
    const StakedNetvrkLand = await ethers.getContractFactory(
      "StakedNetvrkLand"
    );
    staking = await upgrades.deployProxy(StakedNetvrkLand, [nft, baseURI], {
      kind: "uups",
    });

    await staking.deployed();
  }

  console.log("StakedNetvrkLand deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
