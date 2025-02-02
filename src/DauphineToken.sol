// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DauphineToken is ERC20, Ownable {

    constructor(address initialOwner)
        ERC20("DauphineToken", "DAU")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000 * 10 ** decimals()); // Mint DAU to deployer
    }

    // No minter check anymore, anyone can mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
