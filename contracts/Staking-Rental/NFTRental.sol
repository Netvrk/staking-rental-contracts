// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TransferHelper.sol";
import "./INFTStaking.sol";
import "./INFTRental.sol";

contract NFTRental is Context, ERC165, INFTRental, Ownable, ReentrancyGuard {
    using SafeCast for uint256;

    address private immutable ERC20_TOKEN_ADDRESS;
    INFTStaking private immutable NFTStaking;
    mapping(uint256 => RentInformation) private rentInformation;
    mapping(address => uint256) public rentCount; // count of rented nfts per tenant
    mapping(address => mapping(uint256 => uint256)) private _rentedItems; // enumerate rented nfts per tenant
    mapping(uint256 => uint256) private _rentedItemsIndex; // tokenId to index in _rentedItems[tenant]

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
     */
    constructor(address tokenAddress, INFTStaking stakingAddress) {
        require(tokenAddress != address(0), "E0"); // E0: addr err
        require(
            stakingAddress.supportsInterface(type(INFTStaking).interfaceId),
            "E0"
        );
        ERC20_TOKEN_ADDRESS = tokenAddress;
        NFTStaking = stakingAddress;
    }

    // Rescue ERC20 tokens sent directly to this contract
    function rescueERC20(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, _msgSender(), amount);
    }

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
     */

    // Start the rent to a staked token
    function startRent(uint256 tokenId, uint256 initialPayment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(tokenId);
        RentInformation memory rentInformation_ = rentInformation[tokenId];
        require(stakeInfo_.owner != address(0), "EN"); // EN: Not staked
        require(stakeInfo_.enableRenting == true, "ERN"); // ERN: Renting not enabled
        require(
            uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * 86400,
            "EC"
        ); // EC: Not available
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(tokenId);
            require(paidUntil < block.timestamp, "EB"); // EB: Ongoing rent
        }
        // should pay at least deposit + 1 day of rent
        require(
            initialPayment >= (stakeInfo_.deposit + stakeInfo_.rentalPerDay),
            "ED"
        ); // ED: Payment insufficient
        // prevent the user from paying too much
        // block.timestamp casts it into uint256 which is desired
        // if the rentable time left is less than minRentDays then the tenant just has to pay up until the time limit
        uint256 paymentAmount = Math.min(
            ((stakeInfo_.rentableUntil - block.timestamp) *
                stakeInfo_.rentalPerDay) / 86400,
            initialPayment
        );
        rentInformation_.tenant = _msgSender();
        rentInformation_.rentStartTime = block.timestamp.toUint32();
        rentInformation_.rentalPaid += paymentAmount;
        TransferHelper.safeTransferFrom(
            ERC20_TOKEN_ADDRESS,
            _msgSender(),
            stakeInfo_.owner,
            paymentAmount
        );
        rentInformation[tokenId] = rentInformation_;
        uint256 count = rentCount[_msgSender()];
        _rentedItems[_msgSender()][count] = tokenId;
        _rentedItemsIndex[tokenId] = count;
        rentCount[_msgSender()]++;
        emit Rented(tokenId, _msgSender(), paymentAmount);
    }

    // Used by tenant to pay rent in advance. As soon as the tenant defaults the renter can vacate the tenant
    // The rental period can be extended as long as rent is prepaid, up to rentableUntil timestamp.
    // payment unit in ether
    function payRent(uint256 tokenId, uint256 payment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(tokenId);
        RentInformation memory rentInformation_ = rentInformation[tokenId];
        require(rentInformation_.tenant == _msgSender(), "EE"); // EE: Not rented
        // prevent the user from paying too much
        uint256 paymentAmount = Math.min(
            (uint256(
                stakeInfo_.rentableUntil - rentInformation_.rentStartTime
            ) * stakeInfo_.rentalPerDay) /
                86400 -
                rentInformation_.rentalPaid,
            payment
        );
        rentInformation_.rentalPaid += paymentAmount;
        TransferHelper.safeTransferFrom(
            ERC20_TOKEN_ADDRESS,
            _msgSender(),
            stakeInfo_.owner,
            paymentAmount
        );
        rentInformation[tokenId] = rentInformation_;
        emit RentPaid(tokenId, _msgSender(), paymentAmount);
    }

    // Used by renter to vacate tenant in case of default, or when rental period expires.
    // If payment + deposit covers minRentDays then deposit can be used as rent. Otherwise rent has to be provided in addition to the deposit.
    // If rental period is shorter than minRentDays then deposit will be forfeited.
    function terminateRent(uint256 tokenId) external virtual override {
        require(
            NFTStaking.getStakeInformation(tokenId).owner == _msgSender(),
            "E9"
        ); // E9: Not your nft
        uint256 paidUntil = rentalPaidUntil(tokenId);
        require(paidUntil < block.timestamp, "EB"); // EB: Ongoing rent
        address tenant = rentInformation[tokenId].tenant;
        emit RentTerminated(tokenId, tenant);
        rentCount[tenant]--;
        uint256 lastIndex = rentCount[tenant];
        uint256 tokenIndex = _rentedItemsIndex[tokenId];
        // swap and purge if not the last one
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _rentedItems[tenant][lastIndex];

            _rentedItems[tenant][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _rentedItemsIndex[lastTokenId] = tokenIndex;
        }
        delete _rentedItemsIndex[tokenId];
        delete _rentedItems[tenant][tokenIndex];

        rentInformation[tokenId] = RentInformation(address(0), 0, 0);
    }

    /**
    ////////////////////////////////////////////////////
    // View Only Functions 
    ///////////////////////////////////////////////////
     */
    function isRentActive(uint256 tokenId) public view override returns (bool) {
        return rentInformation[tokenId].tenant != address(0);
    }

    function getTenant(uint256 tokenId) public view override returns (address) {
        return rentInformation[tokenId].tenant;
    }

    function rentByIndex(address tenant, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < rentCount[tenant], "EI"); // EI: index out of bounds
        return _rentedItems[tenant][index];
    }

    function isRentable(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool state)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(tokenId);
        RentInformation memory rentInformation_ = rentInformation[tokenId];
        state =
            (stakeInfo_.owner != address(0)) &&
            (uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * 86400);
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(tokenId);
            state = state && (paidUntil < block.timestamp);
        }
    }

    // Get rental amount paid until now
    function rentalPaidUntil(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 paidUntil)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(tokenId);
        RentInformation memory rentInformation_ = rentInformation[tokenId];
        if (stakeInfo_.rentalPerDay == 0) {
            paidUntil = stakeInfo_.rentableUntil;
        } else {
            uint256 rentalPaidSeconds = (uint256(rentInformation_.rentalPaid) *
                86400) / stakeInfo_.rentalPerDay;
            bool fundExceedsMin = rentalPaidSeconds >=
                Math.max(
                    stakeInfo_.minRentDays * 86400,
                    block.timestamp - rentInformation_.rentStartTime
                );
            paidUntil =
                uint256(rentInformation_.rentStartTime) +
                rentalPaidSeconds -
                (
                    fundExceedsMin
                        ? 0
                        : (uint256(stakeInfo_.deposit) * 86400) /
                            stakeInfo_.rentalPerDay
                );
        }
    }

    // Get rent information
    function getRentInformation(uint256 tokenId)
        external
        view
        override
        returns (RentInformation memory)
    {
        return rentInformation[tokenId];
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
            interfaceId == type(INFTRental).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
