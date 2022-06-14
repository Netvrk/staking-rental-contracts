// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv";
import { defender, ethers, upgrades } from "hardhat";
dotenv.config();

async function main() {
  const proxyAddress = "0x1efb6a3125b509983c1ad95e8015d1e93398997d";
  const PURPOSE_REQ = 0;
  const nft = "0xB95aBD5fa9E71f1981505c3D9A7800c369b0718c";
  const baseURI = "https://api.netvrk.co/api/transport/";
  let staking = null;

  if (proxyAddress) {
    if (PURPOSE_REQ) {
      const StakedNetvrkTransport = await ethers.getContractFactory(
        "StakedNetvrkTransport"
      );
      const proposal = await defender.proposeUpgrade(
        proxyAddress,
        StakedNetvrkTransport,
        {
          multisig: process.env.MULTI_SIG,
          title: "Upgrade staking contract",
          description: "Upgrade with some changes",
        }
      );
      console.log("Upgrade proposal created at:", proposal.url);
    } else {
      const StakedNetvrkTransport = await ethers.getContractFactory(
        "StakedNetvrkTransport"
      );
      staking = await upgrades.upgradeProxy(
        proxyAddress,
        StakedNetvrkTransport
      );
      await staking.deployed();
    }
  } else {
    const StakedNetvrkTransport = await ethers.getContractFactory(
      "StakedNetvrkTransport"
    );
    staking = await upgrades.deployProxy(
      StakedNetvrkTransport,
      [nft, baseURI],
      {
        kind: "uups",
      }
    );

    await staking.deployed();
  }

  console.log("StakedNetvrkTransport deployed to:", staking?.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
