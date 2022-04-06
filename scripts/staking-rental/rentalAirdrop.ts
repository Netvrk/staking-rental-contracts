import { ethers } from "hardhat";

async function main() {
  const token = "0x316c062E0F0ee5A3A0B6182BE6Ca4c54A464698f"; // TODO: update this
  const staking = "0x65D69e39A5f01287b16e62742545CdEdBD709fD1"; // TODO: update this

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
