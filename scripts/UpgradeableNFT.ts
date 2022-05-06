const { ethers, upgrades } = require("hardhat");

async function main() {
  const UpgradeableNFT = await ethers.getContractFactory("UpgradeableNFT");

  const upgradeableNFT = await upgrades.deployProxy(UpgradeableNFT, {
    initializer: "initialize",
  });
  await upgradeableNFT.deployed();

  console.log("UpgradeableNFT deployed to: ", upgradeableNFT.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors. "XYZ" "XYZ" "https://www.example.com/"
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
