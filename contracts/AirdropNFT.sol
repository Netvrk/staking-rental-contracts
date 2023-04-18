// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AirdropNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private ctr;

    string internal _baseTokenURI;

    bool public isMintingLocked = false;
    mapping(address => bool) public minters;

    event MintingLocked();
    event MinterAdded(address _account);
    event MinterRemoved(address _account);

    event MintBatchAirdrop(address[] _addresses, uint256 _startTokenId);
    event MintToOwner(
        address _owner,
        uint256 _startTokenId,
        uint256 _numTokens
    );
    event TransferBatchAirdrop(
        address _sender,
        address[] _addresses,
        uint256[] _tokenIds
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI_
    ) ERC721(_name, _symbol) {
        _baseTokenURI = baseTokenURI_;

        minters[_msgSender()] = true;
        emit MinterAdded(_msgSender());
    }

    // ~~~ minting control ~~~

    modifier mintingNotLocked() {
        require(!isMintingLocked, "minting is locked");
        _;
    }

    modifier onlyMinters() {
        require(minters[_msgSender()], "sender is not a minter");
        _;
    }

    function addMinter(address _account) public onlyOwner {
        minters[_account] = true;
        emit MinterAdded(_account);
    }

    function removeMinter(address _account) public onlyOwner {
        minters[_account] = false;
        emit MinterRemoved(_account);
    }

    function lockMinting() public onlyOwner mintingNotLocked {
        isMintingLocked = true;
        emit MintingLocked();
    }

    // ~~~ mint batch and airdrop ~~~

    function mintBatchAirdrop(
        address[] memory _addresses
    ) public onlyMinters mintingNotLocked {
        uint256 currentId = ctr.current();
        uint256 tokenId;

        for (uint256 i = 0; i < _addresses.length; i++) {
            ctr.increment();
            tokenId = ctr.current();
            _mint(_addresses[i], tokenId);
        }
        emit MintBatchAirdrop(_addresses, currentId + 1);
    }

    // ~~~ mint to owner - transfer batch airdrop later ~~~

    function mintToOwner(uint256 _numTokens) public onlyOwner mintingNotLocked {
        uint256 currentId = ctr.current();
        uint256 tokenId;

        for (uint256 i = 0; i < _numTokens; i++) {
            ctr.increment();
            tokenId = ctr.current();
            _mint(_msgSender(), tokenId);
        }
        emit MintToOwner(_msgSender(), currentId + 1, _numTokens);
    }

    // ~~~ transfer batch airdrop ~~~

    // if sender is not token owner, token owner must approve sender (minter) in token contract
    function transferBatchAirdrop(
        address[] memory _addresses,
        uint256[] memory _tokenIds
    ) public onlyMinters {
        require(_addresses.length == _tokenIds.length, "array length mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _transfer(_msgSender(), _addresses[i], _tokenIds[i]);
        }
        emit TransferBatchAirdrop(_msgSender(), _addresses, _tokenIds);
    }

    // ~~~ base uri control ~~~

    // Set base URI
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
        // TODO: add event to update subgraph
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
