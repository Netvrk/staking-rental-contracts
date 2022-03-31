import { ethers } from "hardhat";

async function main() {
  const token = "0x165B59a2579BA314D35814B121580b610251A153";
  const staking = "0x55e718441B1679eCCdAfA3c7473376AB34762bdC";

  const NFTRental = await ethers.getContractFactory("NFTRental");
  const rental = await NFTRental.deploy(token, staking);

  await rental.deployed();

  console.log("NFTRental deployed to:", rental.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
