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
  const nft = "0xE9f906d31ADD9729B6e4c4329B8Aa7990c2f039C";
  const baseURI = "https://api.netvrk.co/api/avatar/";
  let staking = null;

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      const StakedNetvrkAvatar = await ethers.getContractFactory(
        "StakedNetvrkAvatar"
      );
      const proposal = await defender.proposeUpgrade(
        proxyAddress,
        StakedNetvrkAvatar,
        {
          multisig: process.env.MULTI_SIG,
          title: "Upgrade staking contract",
          description: "Upgrade with some changes",
        }
      );
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      const StakedNetvrkAvatar = await ethers.getContractFactory(
        "StakedNetvrkAvatar"
      );
      staking = await upgrades.upgradeProxy(proxyAddress, StakedNetvrkAvatar);
      await staking.deployed();
    }
  } else {
    const StakedNetvrkAvatar = await ethers.getContractFactory(
      "StakedNetvrkAvatar"
    );
    staking = await upgrades.deployProxy(StakedNetvrkAvatar, [nft, baseURI], {
      kind: "uups",
    });

    await staking.deployed();
  }

  console.log("StakedNetvrkAvatar deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
