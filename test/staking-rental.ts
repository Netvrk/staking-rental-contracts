import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers, network, upgrades } from "hardhat";
import { NFT, VRK } from "../typechain-types";

describe("NFT World Staking & Rental", function () {
  let nft: NFT;
  let token: VRK;
  let staking: Contract;
  let rental: Contract;
  let owner: Signer;
  let user: Signer;
  let ownerAddress: string;
  let userAddress: string;
  let now: number;

  function getWei(ethAmt: number) {
    return ethers.utils.parseEther(ethAmt.toString());
  }

  // Get signer
  before(async function () {
    [owner, user] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    userAddress = await user.getAddress();
    now = parseInt((new Date().getTime() / 1000).toString());
  });

  it("Deploy AXE NFT.", async function () {
    const nftContract = await ethers.getContractFactory("NFT");
    nft = await nftContract.deploy("XYZ", "XYZ", "https://www.example.com/");
    await nft.deployed();

    expect(await nft.totalSupply()).to.equal(0);
  });

  it("Deploy VRK token.", async function () {
    const tokenContract = await ethers.getContractFactory("VRK");
    token = await tokenContract.deploy();
    await token.deployed();
    const ownerBalance = await token.balanceOf(ownerAddress);
    expect(await token.totalSupply()).to.equal(ownerBalance);

    // Transfer some amount to user
    await token.transfer(userAddress, ethers.utils.parseEther("100000"));
  });

  it("Deploy Staking and Rental contracts.", async function () {
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    staking = await upgrades.deployProxy(NFTStaking, [
      nft.address,
      "https://www.example.com/",
    ]);
    await staking.deployed();

    const NFTRental = await ethers.getContractFactory("NFTRental");
    rental = await upgrades.deployProxy(NFTRental, [
      token.address,
      staking.address,
    ]);
    await rental.deployed();

    // Set Rental contract
    await staking.setRentalContract(rental.address);
    expect(await staking.owner()).to.equal(ownerAddress);
    expect(await rental.owner()).to.equal(ownerAddress);
  });

  it("Mint 3 NFTs to owner and 3 NFTs to user", async function () {
    await nft.mintItem(ownerAddress, 0);
    await nft.mintItem(ownerAddress, 1);
    await nft.mintItem(ownerAddress, 2);

    await nft.mintItem(userAddress, 3);
    await nft.mintItem(userAddress, 4);
    await nft.mintItem(userAddress, 5);

    await nft.mintItem(ownerAddress, 10);
    await nft.mintItem(ownerAddress, 11);
    await nft.mintItem(ownerAddress, 12);

    const userBalance = parseInt((await nft.balanceOf(userAddress)).toString());
    const ownerBalance = parseInt(
      (await nft.balanceOf(ownerAddress)).toString()
    );

    // Check minted balance and totalsupply
    expect(await nft.totalSupply()).to.equal(ownerBalance + userBalance);

    expect(await nft.ownerOf(0)).to.equal(ownerAddress);
  });

  it("Approve owner and user to use their NFTs in staking contract & Approve user to use token", async function () {
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

    // Allowance
    await token
      .connect(user)
      .approve(rental.address, ethers.utils.parseEther("100000000"));
  });

  it("Owner stakes [0,1,2] NFTs to owner", async function () {
    const nextDay = now + 86400 * 2;
    await staking.stake(
      [0, 1, 2],
      ownerAddress,
      getWei(20),
      getWei(50),
      1,
      nextDay,
      true
    );

    expect(await staking.isStakeActive(0), "true");
    expect(await staking.isStakeActive(1), "true");
    expect(await staking.isStakeActive(2), "true");
  });

  it("Owner stakes [3] NFTs with rental disabled and it shouldn't be able to rent", async function () {
    const nextDay = now + 86400 * 2;
    await staking
      .connect(user)
      .stake([3], userAddress, getWei(20), getWei(50), 1, nextDay, false);

    expect(await staking.isStakeActive(3), "true");
    await expect(rental.startRent(3, getWei(100))).to.be.reverted;
  });

  it("User pays rent until stake expires (MAX) to NFT [2]", async function () {
    // Pay less (only deposit)
    await expect(rental.connect(user).startRent(2, getWei(20))).to.be.reverted;
    // Pay high
    await rental.connect(user).startRent(2, getWei(120));
    const stakeInfo = await staking.getStakeInformation(2);
    const paidUntil = (await rental.rentalPaidUntil(2)).add(1);

    expect(stakeInfo.rentableUntil.toString()).to.equal(paidUntil.toString());

    // Unable to terminate
    await expect(rental.terminateRent(2)).to.be.reverted;
  });

  it("User rents [0,1] NFTs, pays 1 day amount + deposit", async function () {
    expect(await rental.isRentActive(0), "false");

    // Start renting with min amount
    await rental.connect(user).startRent(0, getWei(70));
    await rental.connect(user).startRent(1, getWei(70));

    expect(await rental.isRentActive(0), "true");
    expect(await rental.isRentActive(1), "true");
    expect(await rental.ownerOf(0), userAddress);
    expect(await rental.ownerOf(1), userAddress);
  });

  it("Terminate rent after two days to update information", async function () {
    // After the rental time exceeds
    const nextDay = now + 86400 * 3;
    await network.provider.send("evm_setNextBlockTimestamp", [nextDay]);
    await network.provider.send("evm_mine");

    // Terminate rent
    await rental.terminateRent(0);
    expect(await rental.isRentActive(0), "false");

    await rental.terminateRent(2);
    expect(await rental.isRentActive(2), "false");
  });

  it("Update rent information when staking and rent not enabled", async function () {
    const nextDay = now + 86400 * 6;
    // rent disabled
    expect(await rental.isRentActive(0), "false");
    const oldData = await staking.getStakeInformation(0);

    // Update information
    await staking.updateRent([0], 50, 200, 1, nextDay, true);
    const newData = await staking.getStakeInformation(0);

    expect(oldData.deposit.toString()).to.not.equal(newData.deposit.toString());
  });

  it("Extend rental period while rent is active", async function () {
    expect(await rental.isRentActive(1), "true");
    // Extend
    const nextDay = now + 86400 * 5;
    const oldPeriod = (await staking.getStakeInformation(1)).rentableUntil;
    await staking.extendRentalPeriod(1, nextDay);
    const newPeriod = (await staking.getStakeInformation(1)).rentableUntil;
    expect(oldPeriod).to.not.equal(newPeriod);
  });

  it("Can pay rent daily before stake expires. Cant pay after rent is terminated.", async function () {
    await rental.terminateRent(1);

    const nextDay = now + 86400 * 8;
    await staking.stake(
      [11],
      ownerAddress,
      getWei(20),
      getWei(50),
      1,
      nextDay,
      true
    );
    // Initial (deposit + 1 day payment)
    await rental.connect(user).startRent(11, getWei(70));

    // First payment
    let updateDay = now + 86400 * 5;
    await network.provider.send("evm_setNextBlockTimestamp", [updateDay]);
    await network.provider.send("evm_mine");
    await rental.connect(user).payRent(11, getWei(50));

    // Second payment
    updateDay = now + 86400 * 6;
    await network.provider.send("evm_setNextBlockTimestamp", [updateDay]);
    await network.provider.send("evm_mine");
    await rental.connect(user).payRent(11, getWei(50));

    // No payment, can terminate rent
    updateDay = now + 86400 * 7;
    await network.provider.send("evm_setNextBlockTimestamp", [updateDay]);
    await network.provider.send("evm_mine");
    await rental.terminateRent(11);

    // Cannot pay after termination
    await expect(rental.connect(user).payRent(11, getWei(50))).to.be.reverted;
  });

  it("Get original owner of token", async function () {
    const tokenOwner5 = await staking.getOriginalOwner(5);
    const nftOwner5 = await nft.ownerOf(5);
    expect(tokenOwner5, nftOwner5);

    const tokenOwner1 = await staking.getOriginalOwner(1);
    const nftOwner1 = await nft.ownerOf(1);

    expect(nftOwner1).to.be.equal(staking.address);
    expect(nftOwner1).to.be.not.equal(tokenOwner1);
  });

  it("Owner stakes and unstakes [10] NFTs to user after 1 month", async function () {
    const nextDay = now + 86400 * 12;
    expect(await nft.ownerOf(10), ownerAddress);
    await staking.stake(
      [10],
      ownerAddress,
      getWei(20),
      getWei(50),
      1,
      nextDay,
      true
    );
    expect(await staking.isStakeActive(10), "true");

    const updateDay = nextDay + 86400 * 30;
    await network.provider.send("evm_setNextBlockTimestamp", [updateDay]);
    await network.provider.send("evm_mine");

    await staking.unstake([10], userAddress);

    expect(await staking.isStakeActive(10), "false");
    expect(await nft.ownerOf(10), userAddress);
  });
});
