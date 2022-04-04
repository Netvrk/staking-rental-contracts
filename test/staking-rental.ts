import { expect } from "chai";
import { Signer } from "ethers";
import { ethers, network } from "hardhat";
import { NFT, NFTStaking, NFTRental, NRGY } from "../typechain-types";

describe("NFT World Staking & Rental", function () {
  let nft: NFT;
  let token: NRGY;
  let staking: NFTStaking;
  let rental: NFTRental;
  let owner: Signer;
  let user: Signer;
  let ownerAddress: string;
  let userAddress: string;

  // Get signer
  before(async function () {
    [owner, user] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    userAddress = await user.getAddress();

    // Set initial time
    await network.provider.send("evm_setNextBlockTimestamp", [1648875200]);
    await network.provider.send("evm_mine");
  });

  it("Should deploy AXE NFT.", async function () {
    const nftContract = await ethers.getContractFactory("NFT");
    nft = await nftContract.deploy("XYZ", "XYZ", "https://www.example.com/");
    await nft.deployed();

    expect(await nft.totalSupply()).to.equal(0);
  });

  it("Should deploy NRGY token.", async function () {
    const tokenContract = await ethers.getContractFactory("NRGY");
    token = await tokenContract.deploy();
    await token.deployed();
    const ownerBalance = await token.balanceOf(ownerAddress);
    expect(await token.totalSupply()).to.equal(ownerBalance);

    // Transfer some amount to user
    await token.transfer(userAddress, ethers.utils.parseEther("100000"));
  });

  it("Should deploy Staking and Rental contracts.", async function () {
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    staking = await NFTStaking.deploy(nft.address);
    await staking.deployed();

    const NFTRental = await ethers.getContractFactory("NFTRental");
    rental = await NFTRental.deploy(token.address, staking.address);
    await rental.deployed();

    // Set Rental contract
    await staking.setRentalContract(rental.address);

    expect(await staking.owner()).to.equal(ownerAddress);
    expect(await rental.owner()).to.equal(ownerAddress);
  });

  it("Should mint 3 NFTs to owner and 3 NFTs to user", async function () {
    await nft.mintItem(ownerAddress, 0);
    await nft.mintItem(ownerAddress, 1);
    await nft.mintItem(ownerAddress, 2);

    await nft.mintItem(userAddress, 3);
    await nft.mintItem(userAddress, 4);
    await nft.mintItem(userAddress, 5);

    const userBalance = parseInt((await nft.balanceOf(userAddress)).toString());
    const ownerBalance = parseInt(
      (await nft.balanceOf(ownerAddress)).toString()
    );

    // Check minted balance and totalsupply
    expect(await nft.totalSupply()).to.equal(ownerBalance + userBalance);

    expect(await nft.ownerOf(0)).to.equal(ownerAddress);
  });

  it("Should approve owner and user to use their NFTs in staking contract", async function () {
    await nft.setApprovalForAll(staking.address, true);
    await nft.connect(user).setApprovalForAll(staking.address, true);

    const ownerApproved = await nft.isApprovedForAll(
      ownerAddress,
      staking.address
    );
    expect(ownerApproved, "true");

    const userApproved = await nft.isApprovedForAll(
      userAddress,
      staking.address
    );
    expect(userApproved, "true");
  });

  it("Should stake [0,1,2] NFTs of owner", async function () {
    await staking.stake([0, 1, 2], ownerAddress, 20, 50, 1, 1649021155);

    expect(await staking.isStakeActive(0), "true");
    expect(await staking.isStakeActive(1), "true");
    expect(await staking.isStakeActive(2), "true");
  });

  it("Should unstake [2] NFTs of owner to owner", async function () {
    expect(await staking.isStakeActive(2), "true");
    await staking.unstake([2], ownerAddress);

    expect(await staking.isStakeActive(2), "false");
  });

  it("Should unstake [2] NFTs of owner to user", async function () {
    expect(await nft.ownerOf(2), ownerAddress);
    await staking.stake([2], ownerAddress, 20, 50, 1, 1649021155);
    expect(await staking.isStakeActive(2), "true");
    await staking.unstake([2], userAddress);

    expect(await staking.isStakeActive(2), "false");
    expect(await nft.ownerOf(2), userAddress);
  });

  it("User should rent [0,1] NFTs", async function () {
    // Allowance
    await token
      .connect(user)
      .approve(rental.address, ethers.utils.parseEther("100000000"));

    expect(await rental.isRentActive(0), "false");

    await rental.connect(user).startRent(0, 100);

    await rental.connect(user).startRent(1, 100);

    expect(await rental.isRentActive(0), "true");
    expect(await rental.isRentActive(1), "true");
    expect(await rental.getTenant(0), userAddress);
    expect(await rental.getTenant(1), userAddress);
  });

  it("Terminate rent after 2 days", async function () {
    // After the rental time exceeds
    await network.provider.send("evm_setNextBlockTimestamp", [1649021156]);
    await network.provider.send("evm_mine");

    // Terminate rent
    await rental.terminateRent(0);
    expect(await rental.isRentActive(0), "false");
  });

  it("Should update rent Information while staking", async function () {
    expect(await rental.isRentActive(0), "false");
    const oldData = await staking.getStakeInformation(0);
    await staking.updateRent([0], 50, 200, 1, 1651366277);
    const newData = await staking.getStakeInformation(0);

    expect(oldData.deposit.toString()).to.not.equal(newData.deposit.toString());
  });

  it("Should unstake NFT 0", async function () {
    await staking.unstake([0], ownerAddress);
    expect(await staking.getStakingDuration(0), "0");
  });

  it("Should extend rental period", async function () {
    const oldPeriod = (await staking.getStakeInformation(1)).rentableUntil;
    await staking.extendRentalPeriod(1, 1651366277);
    const newPeriod = (await staking.getStakeInformation(1)).rentableUntil;
    expect(oldPeriod).to.not.equal(newPeriod);
  });
});
