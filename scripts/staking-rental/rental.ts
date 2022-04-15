import { ethers } from "hardhat";

async function main() {
  const token = "0x411caE8A9e0FBecdd7cEE35188c4706fF3DA2598";
  const staking = "0x375D32959D3a55Abd7d50Ed297D07EA2a25e3dab";

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
