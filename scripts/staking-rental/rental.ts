import { ethers } from "hardhat";

async function main() {
  const token = "0xbbA8f4eaD56811eE100b7089b684fa09e8f7172B";
  const staking = "0x01c9Fd946DdCFf85c7a7Df763d49DF106D1c0adD";

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
