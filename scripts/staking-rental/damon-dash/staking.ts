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

  const PURPOSE_REQ = false;

  const avatarNFT = "0xe88A781C82d3Eb8b1C1A98C270f2826B8bcc5DBb";

  const baseURI = "https://api.netvrk.co/api/damon-dash/avatar/";

  let staking = null;

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      // Upgrade to a proxy contract with the purpose requested
      const DDStaking = await ethers.getContractFactory("DDStaking");
      const proposal = await defender.proposeUpgrade(proxyAddress, DDStaking, {
        multisig: process.env.MULTI_SIG,
        title: "Upgrade staking contract #1",
        description: "Upgrade with some new changes",
      });
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      // Upgrade the proxy contract to the new version
      const DDStaking = await ethers.getContractFactory("DDStaking");
      staking = await upgrades.upgradeProxy(proxyAddress, DDStaking);
      await staking.deployed();
    }
  } else {
    // Deploy the new version of the staking contract
    const DDStaking = await ethers.getContractFactory("DDStaking");
    staking = await upgrades.deployProxy(DDStaking, [avatarNFT, baseURI], {
      kind: "uups",
    });

    await staking.deployed();
  }

  console.log("DDStaking deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
