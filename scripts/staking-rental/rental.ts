import { ethers } from "hardhat";

async function main() {
  const token = "0x75195E6e635e2ca8DB104FE9D184f334ee89c7b3";
  const staking = "0x24371B215Cc99D15dc8DdDe4D428e87965E005af";

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
