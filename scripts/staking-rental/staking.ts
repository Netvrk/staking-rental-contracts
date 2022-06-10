// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

async function main() {
  const [, user] = await ethers.getSigners();

  const proxyAddress = "0x19002294F4dDCf25B27EF0072552E118a7f0b782";
  const nft = "0x36870C401d2410dae177942E42c84Dc25e8e38C0";
  const baseURI = "https://www.example.com/";
  let staking = null;
  if (proxyAddress) {
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    staking = await upgrades.upgradeProxy(proxyAddress, NFTStaking);
    await staking.deployed();
  } else {
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
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
