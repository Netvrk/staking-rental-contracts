// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./INFTStaking.sol";
import "./INFTRental.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTStaking is Context, INFTStaking, ERC165, Ownable, ReentrancyGuard {
    using SafeCast for uint256;

    IERC721 immutable NFT_ERC721;
    INFTRental private NFT_RENTAL;
    mapping(uint256 => StakeInformation) private stakeInformation;

    // ======== Admin functions ========

    constructor(address nftAddress) {
        require(nftAddress != address(0), "E0");
        NFT_ERC721 = IERC721(nftAddress);
    }

    function setRentalContract(INFTRental _contract) external onlyOwner {
        require(
            _contract.supportsInterface(type(INFTRental).interfaceId),
            "E0"
        );
        NFT_RENTAL = _contract;
    }

    // ======== Public functions ========

    // subsequent staking does not require dev signature
    function stake(
        uint256[] calldata tokenIds,
        address stakeTo,
        uint16 _deposit,
        uint16 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil
    ) external virtual override nonReentrant {
        require(
            uint256(_deposit) <=
                uint256(_rentalPerDay) * (uint256(_minRentDays) + 1),
            "ER"
        ); // ER: Rental rate incorrect
        // ensure stakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(stakeTo);
        require(stakeTo != address(this), "ES"); // ES: Stake to escrow

        require(
            _rentableUntil >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "ET"
        ); // ET: Rentable until atleast minRentDays

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(NFT_ERC721.ownerOf(tokenId) == _msgSender(), "E9"); // E9: Not your world
            NFT_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);
            stakeInformation[tokenId] = StakeInformation(
                stakeTo,
                _deposit,
                _rentalPerDay,
                _minRentDays,
                _rentableUntil,
                uint32(block.timestamp)
            );

            emit Staked(tokenId, stakeTo);
        }
    }

    // Update rental conditions as long as therer's no ongoing rent.
    // setting rentableUntil to 0 makes the world unrentable.
    function updateRent(
        uint256[] calldata tokenIds,
        uint16 _deposit,
        uint16 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil
    ) external virtual override {
        require(
            uint256(_deposit) <=
                uint256(_rentalPerDay) * (uint256(_minRentDays) + 1),
            "ER"
        ); // ER: Rental rate incorrect

        require(
            _rentableUntil >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "ET"
        ); // ET: Rentable until atleast minRentDays

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeInformation storage stakeInformation_ = stakeInformation[
                tokenId
            ];
            require(
                NFT_ERC721.ownerOf(tokenId) == address(this) &&
                    stakeInformation_.owner == _msgSender(),
                "E9"
            ); // E9: Not your world
            require(!NFT_RENTAL.isRentActive(tokenId), "EB"); // EB: Ongoing rent

            stakeInformation_.deposit = _deposit;
            stakeInformation_.rentalPerDay = _rentalPerDay;
            stakeInformation_.minRentDays = _minRentDays;
            stakeInformation_.rentableUntil = _rentableUntil;
        }
    }

    // Extend rental period of ongoing rent
    function extendRentalPeriod(uint256 tokenId, uint32 _rentableUntil)
        external
        virtual
        override
    {
        StakeInformation storage stakeInformation_ = stakeInformation[tokenId];
        require(
            NFT_ERC721.ownerOf(tokenId) == address(this) &&
                stakeInformation_.owner == _msgSender(),
            "E9"
        ); // E9: Not your world
        require(
            _rentableUntil >=
                block.timestamp +
                    (uint256(stakeInformation_.minRentDays) * 1 days),
            "ET"
        ); // ET: Rentable until atleast minRentDays
        stakeInformation_.rentableUntil = _rentableUntil;
    }

    function unstake(uint256[] calldata tokenIds, address unstakeTo)
        external
        virtual
        override
        nonReentrant
    {
        // ensure unstakeTo is EOA or ERC721Receiver to avoid token lockup
        _ensureEOAorERC721Receiver(unstakeTo);
        require(unstakeTo != address(this), "ES"); // ES: Unstake to escrow

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(stakeInformation[tokenId].owner == _msgSender(), "E9"); // E9: Not your world
            require(!NFT_RENTAL.isRentActive(tokenId), "EB"); // EB: Ongoing rent
            NFT_ERC721.safeTransferFrom(address(this), unstakeTo, tokenId);
            stakeInformation[tokenId] = StakeInformation(
                address(0),
                0,
                0,
                0,
                0,
                0
            );

            emit Unstaked(tokenId, _msgSender());
        }
    }

    // ======== View only functions ========

    function getStakeInformation(uint256 tokenId)
        external
        view
        override
        returns (StakeInformation memory)
    {
        return stakeInformation[tokenId];
    }

    function getStakingDuration(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (stakeInformation[tokenId].stakedFrom == 0) {
            return 0;
        }
        return block.timestamp - stakeInformation[tokenId].stakedFrom;
    }

    function isStakeActive(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return stakeInformation[tokenId].owner != address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTStaking).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        from;
        tokenId;
        data; // supress solidity warnings
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        } else {
            return 0x00000000;
        }
    }

    // ======== internal functions ========

    function _ensureEOAorERC721Receiver(address to) internal virtual {
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    address(this),
                    address(this),
                    0,
                    ""
                )
            returns (bytes4 retval) {
                require(
                    retval == IERC721Receiver.onERC721Received.selector,
                    "ET"
                ); // ET: neither EOA nor ERC721Receiver
            } catch (bytes memory) {
                revert("ET"); // ET: neither EOA nor ERC721Receiver
            }
        }
    }
}
