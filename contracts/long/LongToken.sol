// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LongToken is ERC20, Ownable {
    uint256 private constant preMineSupply = 10_000_000_000 ether;

    constructor() public ERC20("LONG", "LONG") {
        
        _mint(msg.sender, preMineSupply);
    }

}

