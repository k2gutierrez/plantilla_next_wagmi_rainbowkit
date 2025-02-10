// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin's libraries for secure token transfers and access control.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error TokenHolder__NotOwner();
error TokenHolder__InsufficientTokenBalance();

/// @dev Minimal interface for ERC20 tokens that support burning.
interface IERC20Burnable is IERC20 {
    /// @notice Burns a specific amount of tokens from the caller's balance.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external;
}

contract TokenHolder {
    using SafeERC20 for IERC20;

    address private immutable i_owner;

    address private blancoToken;

    address private reposadoToken;
    address private sellReposadoToken;
    address private sendReposadoToken;

    address private anejoToken;
    address private sellAnejoToken;
    address private sendAnejoToken;

    // Events for logging token withdrawals.
    event TokenWithdrawn(address indexed token, uint256 amount, address indexed to);
    event TokenBurned(address indexed token, uint256 amount);

    constructor () {
        i_owner = msg.sender;
    }

    modifier onlyOwner(){
        if (msg.sender != i_owner) revert TokenHolder__NotOwner();
        _;
    }

    function setBlancoBottleToken(address _token) external onlyOwner {
        blancoBottleToken = _token;
    }

    function setReposadoBottleToken(address _token) external onlyOwner {
        reposadoBottleToken = _token;
    }

    function setAnejoBottleToken(address _token) external onlyOwner {
        anejoBottleToken = _token;
    }

    function setSellBottleToken(address _token) external onlyOwner {
        sellBottleToken = _token;
    }

    function setSendBottleToken(address _token) external onlyOwner {
        sendBottleToken = _token;
    }

    /**
     * @notice Returns the balance of a given ERC‑20 token held by this contract.
     * @param token The address of the ERC‑20 token contract.
     * @return The balance of the token for this contract.
     */
    function tokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Burns a specified amount of ERC‑20 tokens held by this contract.
     * @dev The token must implement a burn function (e.g. be based on OpenZeppelin’s ERC20Burnable).
     * @param token The address of the ERC‑20 token to burn.
     * @param amount The amount of tokens to burn.
     */
    function burnToken(address token, uint256 amount) external onlyOwner {
        uint256 balance = tokenBalance(token);
        require(amount <= balance, "Insufficient token balance to burn");

        // Call the burn function on the token.
        IERC20Burnable(token).burn(amount);
        emit TokenBurned(token, amount);
    }

    /**
     * @notice Allows the owner to withdraw a specified amount of an ERC‑20 token from this contract.
     * @param token The address of the ERC‑20 token.
     * @param amount The amount of tokens to withdraw.
     * @param to The address to send the tokens to.
     */
    function withdrawToken(address token, uint256 amount, address to) external onlyOwner {
        uint256 balance = tokenBalance(token);
        if (amount > balance) revert TokenHolder__InsufficientTokenBalance();
        // Use SafeERC20 to transfer the tokens safely.
        IERC20(token).safeTransfer(to, amount);
        emit TokenWithdrawn(token, amount, to);
    }

}