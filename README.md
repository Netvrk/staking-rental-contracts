# Staking Rental Contracts

This project includes the staking and rental contracts used in the NetVrk ecosystem. When staking, users receive a synthetic NFT with the same token ID, which can be used in the NetVrk metaverse.

### Staking Smart contracts [mainnet]
- Staked Netvrk Land: [0x1536591a2ae88bbfbb2511b0808696bc0266dca0](https://etherscan.io/address/0x1536591a2ae88bbfbb2511b0808696bc0266dca0)
- Staked Netvrk Bonus: [0x543b2579513fec396fb03acc334c2d47e346a42a](https://etherscan.io/address/0x543b2579513fec396fb03acc334c2d47e346a42a)
- Staked Netvrk Transport: [0x1efb6a3125b509983c1ad95e8015d1e93398997d](https://etherscan.io/address/0x1efb6a3125b509983c1ad95e8015d1e93398997d)
- Staked Netvrk Avatars: [0x618f80dE5e32f281C3ACC790e00FC719EFd357A5](https://etherscan.io/address/0x618f80dE5e32f281C3ACC790e00FC719EFd357A5)

### Netvrk Smart contracts [mainnet]
- Netvrk Land: [0x244FC4178fa685Af909c88b4D4CD7eB9127eDb0B](https://etherscan.io/address/0x244FC4178fa685Af909c88b4D4CD7eB9127eDb0B)
- Netvrk Bonus: [0xBCbEaE3620b3280dF67143Ad7eC45d67C5A4355e](https://etherscan.io/address/0xBCbEaE3620b3280dF67143Ad7eC45d67C5A4355e)
- Netvrk Transport: [0xB95aBD5fa9E71f1981505c3D9A7800c369b0718c](https://etherscan.io/address/0xB95aBD5fa9E71f1981505c3D9A7800c369b0718c)
- Netvrk Avatars: [0xdc403FCDf735426e77Fdd3bbD6223a3ac03eF3b3](https://etherscan.io/address/0xdc403FCDf735426e77Fdd3bbD6223a3ac03eF3b3)

## Explanation of Staking and Rental Contracts

### NFTStaking.sol

This contract handles the staking of NFTs. It allows users to stake their NFTs, update rental conditions, extend rental periods, and unstake their NFTs. Key functionalities include:

- **Initialization**: The `initialize` function sets up the contract with the NFT address and base URI. It also initializes the upgradeable, ownable, and reentrancy guard functionalities.

- **Staking**: The `stake` function allows users to stake their NFTs by transferring them to the contract. It records the staking information, including the deposit, rental rate, minimum rental days, and rental period.

- **Updating Rental Conditions**: The `updateRent` function allows users to update the rental conditions of their staked NFTs, provided there is no ongoing rent.

- **Extending Rental Period**: The `extendRentalPeriod` function allows users to extend the rental period of their staked NFTs.

- **Unstaking**: The `unstake` function allows users to unstake their NFTs and remove them from the rental pool, provided there is no ongoing rent and the lock period has expired.

- **View Functions**: Various view functions are provided to get information about the staked NFTs, such as `getNFTAddress`, `getRentalContractAddress`, `getStakeInformation`, `getOriginalOwner`, `getStakingDuration`, and `isStakeActive`.

### NFTRental.sol

This contract handles the rental of staked NFTs. It allows users to start renting staked NFTs, pay rent, and terminate rentals. Key functionalities include:

- **Initialization**: The `initialize` function sets up the contract with the ERC20 token address and the staking contract address. It also initializes the upgradeable, ownable, and reentrancy guard functionalities.

- **Starting Rent**: The `startRent` function allows users to start renting a staked NFT by making an initial payment. It records the rental information, including the tenant address, rental start time, and rental amount paid.

- **Paying Rent**: The `payRent` function allows tenants to pay rent in advance. The rental period can be extended as long as rent is prepaid.

- **Terminating Rent**: The `terminateRent` function allows the owner of the staked NFT to terminate the rental in case of default or when the rental period expires.

- **View Functions**: Various view functions are provided to get information about the rentals, such as `isRentActive`, `isRentable`, `rentalPaidUntil`, and `getRentInformation`.

### Interaction Between Contracts

The NFTStaking.sol and NFTRental.sol contracts interact with each other to manage the staking and rental processes. The staking contract records the staking information and ensures that the NFTs are properly staked and unstaked. The rental contract manages the rental process, ensuring that tenants can rent staked NFTs, pay rent, and terminate rentals as needed.

By using these contracts, the NetVrk ecosystem can efficiently manage the staking and rental of NFTs, providing users with a seamless experience for staking their assets and earning rental income.