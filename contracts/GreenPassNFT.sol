// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GreenPassNFT is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private ctr;

    string internal _baseTokenURI;
    address public landStakingContract;
    address public netvrkTokenStakingContract;

    mapping(uint256 => GreenPass) public greenPasses;

    enum StakeType {
        Land,
        NetvrkToken
    }

    struct GreenPass {
        uint256 tokenId;
        address citizen;
        StakeType stakeType;
        uint256 issuedAt;
        bool active;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    modifier isApprovedStakingContract() {
        require(_msgSender() == landStakingContract || _msgSender() == netvrkTokenStakingContract, "sender not approved contract");
        _;
    }

    // Mint Green Pass
    function mintGreenPass(address _citizen, StakeType _stakeType)
        public
        isApprovedStakingContract
        returns (uint256)
    {
        ctr.increment();
        uint256 _tokenId = ctr.current();
        
        GreenPass memory greenPass = GreenPass({
            tokenId: _tokenId,
            citizen: _citizen,
            stakeType: _stakeType,
            issuedAt: block.timestamp,
            active: true
        });
        
        greenPasses[_tokenId] = greenPass;
        _mint(_citizen, _tokenId);
        
        return _tokenId;
    }

    // Burn Green Pass
    function burnGreenPass(uint256 _tokenId) public isApprovedStakingContract returns (uint256) {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "Caller is not owner nor approved"
        );
        greenPasses[_tokenId].active = false;
        _burn(_tokenId);
        return _tokenId;
    }

    // Set base URI
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
