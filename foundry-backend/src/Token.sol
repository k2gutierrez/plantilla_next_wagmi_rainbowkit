// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MyToken is ERC20, ERC20Burnable {
    /**
     * @notice Constructor that mints the total supply to a specified recipient.
     * @param recipient The address (contract or EOA) that will receive the total supply.
     */
    constructor(address recipient, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        // Calculate the total supply: 5555 tokens, accounting for 18 decimals.
        uint256 totalSupply = 5555 * 10 ** decimals();
        // Mint the total supply directly to the recipient.
        _mint(recipient, totalSupply);
    }
}