// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NRGY is ERC20 {
    constructor() ERC20("Energy", "NRGY") {
        _mint(msg.sender, 1000000 * 1000000000000000000);
    }
}
