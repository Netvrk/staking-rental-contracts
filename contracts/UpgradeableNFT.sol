// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract UpgradeableNFT is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    string internal _baseTokenURI;

    function initialize() public initializer {
        __ERC721_init("PICKAXE", "AXE");
        _baseTokenURI = "https://api.netvrk.co/api/items/";
    }

    // Mint game item
    function mintItem(address player, uint256 itemId)
        public
        onlyOwner
        returns (uint256)
    {
        _mint(player, itemId);
        return itemId;
    }

    // Burn game item
    function burnItem(uint256 itemId) public onlyOwner returns (uint256) {
        require(
            _isApprovedOrOwner(_msgSender(), itemId),
            "Caller is not owner nor approved"
        );
        _burn(itemId);
        return itemId;
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
