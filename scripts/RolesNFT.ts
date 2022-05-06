import { ethers } from "hardhat";

async function main() {
  const nftContract = await ethers.getContractFactory("RolesNFT");
  const nft = await nftContract.deploy(
    "RPICKAXE",
    "RAXE",
    "https://api.netvrk.co/api/items/"
  );
  await nft.deployed();

  console.log("Axe RolesNFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors. "XYZ" "XYZ" "https://www.example.com/"
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
