// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TransferHelper.sol";
import "./INFTStaking.sol";
import "./INFTRental.sol";

contract NFTRental is
    Initializable,
    ContextUpgradeable,
    INFTRental,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721EnumerableUpgradeable
{
    using SafeCastUpgradeable for uint256;

    address private ERC20_TOKEN_ADDRESS;
    INFTStaking private NFTStaking;
    mapping(uint256 => RentInformation) private rentInformation;

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
     */
    function initialize(address _tokenAddress, INFTStaking _stakingAddress)
        public
        initializer
    {
        require(_tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(
            _stakingAddress.supportsInterface(type(INFTStaking).interfaceId),
            "INVALID_STAKING_ADDRESS"
        );
        __ERC721_init("Rental", "RNTL");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        ERC20_TOKEN_ADDRESS = _tokenAddress;
        NFTStaking = _stakingAddress;
    }

    // Rescue ERC20 tokens sent directly to this contract
    function rescueERC20(address _token, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_token, _msgSender(), _amount);
    }

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
     */

    // Start the rent to a staked token
    function startRent(uint256 _tokenId, uint256 _initialPayment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        require(stakeInfo_.owner != address(0), "NOT_STAKED");
        require(stakeInfo_.enableRenting == true, "RENT_DISABLED");
        require(
            uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * (1 days),
            "NOT_AVAILABLE"
        );
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(_tokenId);
            require(paidUntil < block.timestamp, "ACTIVE_RENT");
        }
        // should pay at least deposit + 1 day of rent
        require(
            _initialPayment >= (stakeInfo_.deposit + stakeInfo_.rentalPerDay),
            "INSUFFICENT_PAYMENT"
        );
        // prevent the user from paying too much
        // block.timestamp casts it into uint256 which is desired
        // if the rentable time left is less than minRentDays then the tenant just has to pay up until the time limit
        uint256 paymentAmount = MathUpgradeable.min(
            ((stakeInfo_.rentableUntil - block.timestamp) *
                stakeInfo_.rentalPerDay) / (1 days),
            _initialPayment
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
        rentInformation[_tokenId] = rentInformation_;

        _safeMint(_msgSender(), _tokenId);
        emit Rented(_tokenId, _msgSender(), paymentAmount);
    }

    // Used by tenant to pay rent in advance. As soon as the tenant defaults the renter can vacate the tenant
    // The rental period can be extended as long as rent is prepaid, up to rentableUntil timestamp.
    // payment unit in ether
    function payRent(uint256 _tokenId, uint256 _payment)
        external
        virtual
        override
        nonReentrant
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        require(rentInformation_.tenant == _msgSender(), "NOT_RENTED");
        // prevent the user from paying too much
        uint256 paymentAmount = MathUpgradeable.min(
            (uint256(
                stakeInfo_.rentableUntil - rentInformation_.rentStartTime
            ) * stakeInfo_.rentalPerDay) /
                (1 days) -
                rentInformation_.rentalPaid,
            _payment
        );
        rentInformation_.rentalPaid += paymentAmount;
        TransferHelper.safeTransferFrom(
            ERC20_TOKEN_ADDRESS,
            _msgSender(),
            stakeInfo_.owner,
            paymentAmount
        );
        rentInformation[_tokenId] = rentInformation_;
        emit RentPaid(_tokenId, _msgSender(), paymentAmount);
    }

    // Used by renter to vacate tenant in case of default, or when rental period expires.
    // If payment + deposit covers minRentDays then deposit can be used as rent. Otherwise rent has to be provided in addition to the deposit.
    // If rental period is shorter than minRentDays then deposit will be forfeited.
    function terminateRent(uint256 _tokenId) external virtual override {
        require(
            NFTStaking.getStakeInformation(_tokenId).owner == _msgSender(),
            "NFT_NOT_OWNED"
        );
        uint256 paidUntil = rentalPaidUntil(_tokenId);
        require(paidUntil < block.timestamp, "ACTIVE_RENT");
        address tenant = rentInformation[_tokenId].tenant;

        rentInformation[_tokenId] = RentInformation(address(0), 0, 0);
        _burn(_tokenId);
        emit RentTerminated(_tokenId, tenant);
    }

    /**
    ////////////////////////////////////////////////////
    // View Only Functions 
    ///////////////////////////////////////////////////
     */
    function isRentActive(uint256 _tokenId)
        public
        view
        override
        returns (bool)
    {
        return
            rentInformation[_tokenId].tenant != address(0) &&
            ownerOf(_tokenId) != address(0);
    }

    function isRentable(uint256 _tokenId)
        external
        view
        virtual
        override
        returns (bool state)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        state =
            (stakeInfo_.owner != address(0)) &&
            (uint256(stakeInfo_.rentableUntil) >=
                block.timestamp + stakeInfo_.minRentDays * (1 days));
        if (rentInformation_.tenant != address(0)) {
            // if previously rented
            uint256 paidUntil = rentalPaidUntil(_tokenId);
            state = state && (paidUntil < block.timestamp);
        }
    }

    // Get rental amount paid until now
    function rentalPaidUntil(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (uint256 paidUntil)
    {
        INFTStaking.StakeInformation memory stakeInfo_ = NFTStaking
            .getStakeInformation(_tokenId);
        RentInformation memory rentInformation_ = rentInformation[_tokenId];
        if (stakeInfo_.rentalPerDay == 0) {
            paidUntil = stakeInfo_.rentableUntil;
        } else {
            uint256 rentalPaidSeconds = (uint256(rentInformation_.rentalPaid) *
                (1 days)) / stakeInfo_.rentalPerDay;
            bool fundExceedsMin = rentalPaidSeconds >=
                MathUpgradeable.max(
                    stakeInfo_.minRentDays * (1 days),
                    block.timestamp - rentInformation_.rentStartTime
                );
            paidUntil =
                uint256(rentInformation_.rentStartTime) +
                rentalPaidSeconds -
                (
                    fundExceedsMin
                        ? 0
                        : (uint256(stakeInfo_.deposit) * (1 days)) /
                            stakeInfo_.rentalPerDay
                );
        }
    }

    // Get rent information
    function getRentInformation(uint256 _tokenId)
        external
        view
        override
        returns (RentInformation memory)
    {
        return rentInformation[_tokenId];
    }

    /**
    ////////////////////////////////////////////////////
    // Internal Functions 
    ///////////////////////////////////////////////////
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_LOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTRental).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
