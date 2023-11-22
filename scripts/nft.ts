import { ethers } from "hardhat";

async function main() {
  const nftContract = await ethers.getContractFactory("NFT");
  const nft = await nftContract.deploy(
    "TRN",
    "TRN",
    "https://example.com/transport/"
  );
  await nft.deployed();

  console.log("Land NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors. "XYZ" "XYZ" "https://www.example.com/"
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
