import { ethers } from "hardhat";

async function main() {
  const nftContract = await ethers.getContractFactory("AirdropNFT");
  const nft = await nftContract.deploy(
    "ABC",
    "ABC",
    "https://www.example.com/"
  );
  await nft.deployed();

  console.log("Airdrop NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors. "ABC" "ABC" "https://www.example.com/"
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
