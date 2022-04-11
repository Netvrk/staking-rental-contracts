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

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
     */
    constructor(address nftAddress) {
        require(nftAddress != address(0), "INVALID_NFT_ADDRESS");
        NFT_ERC721 = IERC721(nftAddress);
    }

    function setRentalContract(INFTRental _contract) external onlyOwner {
        require(
            _contract.supportsInterface(type(INFTRental).interfaceId),
            "INVALID_RENTAL_ADDRESS"
        );
        NFT_RENTAL = _contract;
    }

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
     */

    // Stake the NFT token
    function stake(
        uint256[] calldata tokenIds,
        address stakeTo,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRenting
    ) external virtual override nonReentrant {
        require(
            _deposit <= _rentalPerDay * (uint256(_minRentDays) + 1),
            "INVALID_RATE"
        );
        _ensureEOAorERC721Receiver(stakeTo);
        require(stakeTo != address(this), "INVALID_STAKE_TO");
        require(
            _rentableUntil >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                NFT_ERC721.ownerOf(tokenId) == _msgSender(),
                "NFT_NOT_OWNED"
            );
            NFT_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);
            stakeInformation[tokenId] = StakeInformation(
                stakeTo,
                _deposit,
                _rentalPerDay,
                _minRentDays,
                _rentableUntil,
                uint32(block.timestamp),
                _enableRenting
            );

            emit Staked(tokenId, stakeTo);
        }
    }

    // Set Renting while staking
    function setRenting(uint256[] calldata tokenIds, bool _enableRenting)
        external
        virtual
        override
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeInformation storage stakeInfo_ = stakeInformation[tokenId];
            stakeInfo_.enableRenting = _enableRenting;
        }
    }

    // Update rental conditions as long as therer's no ongoing rent.
    // setting rentableUntil to 0 makes the world unrentable.
    function updateRent(
        uint256[] calldata tokenIds,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRenting
    ) external virtual override {
        require(
            _deposit <= _rentalPerDay * (uint256(_minRentDays) + 1),
            "INVALID_RATE"
        );

        require(
            _rentableUntil >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeInformation storage stakeInfo_ = stakeInformation[tokenId];
            require(
                NFT_ERC721.ownerOf(tokenId) == address(this) &&
                    stakeInfo_.owner == _msgSender(),
                "NFT_NOT_OWNED"
            );
            require(!NFT_RENTAL.isRentActive(tokenId), "ACTIVE_RENT"); // EB: Ongoing rent

            stakeInfo_.deposit = _deposit;
            stakeInfo_.rentalPerDay = _rentalPerDay;
            stakeInfo_.minRentDays = _minRentDays;
            stakeInfo_.rentableUntil = _rentableUntil;
            stakeInfo_.enableRenting = _enableRenting;
        }
    }

    // Extend rental period of ongoing rent
    function extendRentalPeriod(uint256 tokenId, uint32 _rentableUntil)
        external
        virtual
        override
    {
        StakeInformation storage stakeInfo_ = stakeInformation[tokenId];
        require(
            NFT_ERC721.ownerOf(tokenId) == address(this) &&
                stakeInfo_.owner == _msgSender(),
            "NFT_NOT_OWNED"
        ); // E9: Not your world
        require(
            _rentableUntil >=
                block.timestamp + (uint256(stakeInfo_.minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );
        stakeInfo_.rentableUntil = _rentableUntil;
    }

    // Unstake tokens and remove rental
    function unstake(uint256[] calldata tokenIds, address unstakeTo)
        external
        virtual
        override
        nonReentrant
    {
        _ensureEOAorERC721Receiver(unstakeTo);
        require(unstakeTo != address(this), "INVALID_STAKE_TO");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                stakeInformation[tokenId].owner == _msgSender(),
                "NFT_NOT_OWNED"
            );
            require(!NFT_RENTAL.isRentActive(tokenId), "ACTIVE_RENT"); // EB: Ongoing rent
            NFT_ERC721.safeTransferFrom(address(this), unstakeTo, tokenId);
            stakeInformation[tokenId] = StakeInformation(
                address(0),
                0,
                0,
                0,
                0,
                0,
                false
            );
            emit Unstaked(tokenId, _msgSender());
        }
    }

    /**
    ////////////////////////////////////////////////////
    // View only functions
    ///////////////////////////////////////////////////
     */

    // Get stake information
    function getStakeInformation(uint256 tokenId)
        external
        view
        override
        returns (StakeInformation memory)
    {
        return stakeInformation[tokenId];
    }

    // Get owner of the staking tokens
    function getOriginalOwner(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        if (NFT_ERC721.ownerOf(tokenId) == address(this)) {
            return stakeInformation[tokenId].owner;
        }

        return NFT_ERC721.ownerOf(tokenId);
    }

    // Get stake duration information
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

    // Get if the stake is active or inactive
    function isStakeActive(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return stakeInformation[tokenId].owner != address(0);
    }

    /**
    ////////////////////////////////////////////////////
    // Internal Functions 
    ///////////////////////////////////////////////////
     */
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
                    "INVALID_RECEIVER"
                );
            } catch (bytes memory) {
                revert("INVALID_RECEIVER");
            }
        }
    }
}
