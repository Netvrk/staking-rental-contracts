// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTStaking is IERC165, IERC721Receiver {
    event Staked(uint256 indexed tokenId, address indexed user);
    event Unstaked(uint256 indexed tokenId, address indexed user);

    struct StakeInformation {
        address owner; // staked to, otherwise owner == 0
        uint16 deposit; // unit is ether, paid in NRGY. The deposit is deducted from the last payment(s) since the deposit is non-custodial
        uint16 rentalPerDay; // unit is ether, paid in NRGY. Total is deposit + rentalPerDay * days
        uint16 minRentDays; // must rent for at least min rent days, otherwise deposit is forfeited up to this amount
        uint32 rentableUntil; // timestamp in unix epoch
        uint32 stakedFrom;
    }

    // view functions
    function getStakeInformation(uint256 tokenId)
        external
        view
        returns (StakeInformation memory);

    function isStakeActive(uint256 tokenId) external view returns (bool);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4);

    function stake(
        uint256[] calldata tokenIds,
        address stakeTo,
        uint16 _deposit,
        uint16 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil
    ) external;

    function updateRent(
        uint256[] calldata tokenIds,
        uint16 _deposit,
        uint16 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil
    ) external;

    function extendRentalPeriod(uint256 tokenId, uint32 _rentableUntil)
        external;

    function unstake(uint256[] calldata tokenIds, address unstakeTo) external;
}
