// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin's libraries for secure token transfers and access control.
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

error TokenHolder__NotOwner();
error TokenHolder__InsufficientTokenBalance();
error TokenHolder__NoTokenNameSet();
error TokenHolder__WrongTokenName();

/// @dev Minimal interface for ERC20 tokens that support burning.
interface IERC20Burnable is IERC20 {
    /// @notice Burns a specific amount of tokens from the caller's balance.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external;
}

contract TokenHolder {
    using SafeERC20 for IERC20;

    // Owner address
    address private immutable i_owner;
    // Mingle contract
    address private immutable i_mingles;
    // array to hold NFT_IDs registered to trade for Blanco Token
    uint256[] private s_registeredMingles;
    // Mapping to check if nfts has been claimed
    mapping (uint => bool) private NFTexists;
    // Token contract address
    address private s_blancoBottleToken;
    address private s_reposadoBottleToken;
    address private s_anejoBottleToken;
    address private s_sellReposadoBottleToken;
    address private s_sendReposadoBottleToken;
    address private s_sellAnejoBottleToken;
    address private s_sendAnejoBottleToken;

    // Events for logging token withdrawals.
    event TokenWithdrawn(
        address indexed token,
        uint256 amount,
        address indexed to
    );
    event TokenBurned(address indexed token, uint256 amount);

    constructor(address _NFTs) {
        i_owner = msg.sender;
        i_mingles = _NFTs;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert TokenHolder__NotOwner();
        _;
    }

    function setTokenAddress(
        address _blanco,
        address _reposado,
        address _anejo,
        address _sellReposado,
        address _sendReposado,
        address _sellAnejo,
        address _sendAnejo
    ) external onlyOwner {
        s_blancoBottleToken = _blanco;
        s_reposadoBottleToken = _reposado;
        s_anejoBottleToken = _anejo;
        s_sellReposadoBottleToken = _sellReposado;
        s_sendReposadoBottleToken = _sendReposado;
        s_sellAnejoBottleToken = _sellAnejo;
        s_sendAnejoBottleToken = _sendAnejo;
    }

    function seeTokenAddress(bytes32 _token) public view returns (address) {
        if (_token == "") revert TokenHolder__NoTokenNameSet();
        if (_token == "blanco") {
            return s_blancoBottleToken;
        } else if (_token == "reposado") {
            return s_reposadoBottleToken;
        } else if (_token == "anejo") {
            return s_anejoBottleToken;
        } else if (_token == "sellReposado") {
            return s_sellReposadoBottleToken;
        } else if (_token == "sendReposado") {
            return s_sendReposadoBottleToken;
        } else if (_token == "sellAnejo") {
            return s_sellAnejoBottleToken;
        } else if (_token == "sendAnejo") {
            return s_sendAnejoBottleToken;
        } else {
            revert TokenHolder__WrongTokenName();
        }
    }

    // Get registered mingles array
    function getRegisteredMingles() external view returns (uint256[] memory) {
        return s_registeredMingles;
    }

    // Get registered mingles array length
    function getRegisteredMinglesLength() external view returns (uint256) {
        return s_registeredMingles.length;
    }

    // Check if NFT has been claimed
    function checkIfNFTHasBeenClaimed(uint256 _NFTID) external view returns(bool) {
        return NFTexists[_NFTID];
    }

    /**
     * @notice Returns the balance of a given ERC‑20 token held by this contract.
     * @param _token The name of the ERC‑20 token to get the contract address.
     * @return The balance of the token for this contract.
     */
    function tokenContractBalance(
        bytes32 _token
    ) public view returns (uint256) {
        return IERC20(seeTokenAddress(_token)).balanceOf(address(this));
    }

    /**
     * @notice Returns the balance of a given ERC‑20 token held by an user address.
     * @param _token The name of the ERC‑20 token to get the contract address.
     * @return The balance of the token for the given user address.
     */
    function tokenUserBalance(
        bytes32 _token,
        address _user
    ) public view returns (uint256) {
        return IERC20(seeTokenAddress(_token)).balanceOf(_user);
    }

    /**
     * @notice Burns a specified amount of ERC‑20 tokens held by this contract.
     * @dev The token must implement a burn function (e.g. be based on OpenZeppelin’s ERC20Burnable).
     * @param _token The name of the ERC‑20 token to get the address to burn.
     * @param _user The user adress to burn the token and change it for another token or action like sell or send
     * @param amount The amount of tokens to burn.
     */
    function burnToken(bytes32 _token, address _user, uint256 amount) private {
        uint256 balance = tokenUserBalance(_token, _user);
        require(amount <= balance, "Insufficient token balance to burn");

        // Call the burn function on the token.
        IERC20Burnable(seeTokenAddress(_token)).burn(amount);
        emit TokenBurned(seeTokenAddress(_token), amount);
    }

    /**
     * @notice Allows the owner to withdraw a specified amount of an ERC‑20 token from this contract.
     * @param NFTs The array of NFTs and user has
     * @param to The address to send the tokens to.
     */
    function blancoTransferToken(
        uint256[] memory NFTs,
        address to
    ) external {
        uint256 amount;
        bytes32 token = "blanco";
        for (uint256 i; i < NFTs.length; i++) {
            if (ERC721(i_mingles).ownerOf(i) == msg.sender) {
                if (NFTexists[i] == false){
                    s_registeredMingles.push(i);
                    amount++;
                    NFTexists[i] == true;
                }
            }
        }
        uint256 balance = tokenContractBalance(token);
        if (amount > balance) revert TokenHolder__InsufficientTokenBalance();
        // Use SafeERC20 to transfer the tokens safely.
        IERC20(seeTokenAddress(token)).safeTransfer(to, amount);
        emit TokenWithdrawn(seeTokenAddress(token), amount, to);
    }

    /**
     * @notice Allows the owner to withdraw a specified amount of an ERC‑20 token from this contract.
     * @param token The address of the ERC‑20 token.
     * @param amount The amount of tokens to withdraw.
     * @param to The address to send the tokens to.
     
    function blancoTransferToken(address token, uint256 amount, address to) external onlyOwner {
        uint256 balance = tokenContractBalance(token);
        if (amount > balance) revert TokenHolder__InsufficientTokenBalance();
        // Use SafeERC20 to transfer the tokens safely.
        IERC20(token).safeTransfer(to, amount);
        emit TokenWithdrawn(token, amount, to);
    }
    */
}
