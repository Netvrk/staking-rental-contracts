// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./eip-4907/ERC4907.sol";

contract RolesNFT is ERC4907, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string internal _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC4907(name, symbol) {
        _baseTokenURI = baseTokenURI;
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

    // Overrides
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC4907, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4907, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
