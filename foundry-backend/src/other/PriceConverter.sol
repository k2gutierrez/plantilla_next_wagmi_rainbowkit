// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPyth} from "../../lib/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "../../lib/pyth-sdk-solidity/PythStructs.sol";

contract PriceConverter {

    error PriceConverter__NegativePrice();

    IPyth pyth;
    // APE/USD = 0x15add95022ae13563a11992e727c91bdb6b55bc183d9d747436c80a483d8c864
    bytes32 public constant PRICE_FEED_ID = 0x15add95022ae13563a11992e727c91bdb6b55bc183d9d747436c80a483d8c864;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    // Get the current ETH/USD price
    function getEthUsdPrice() public view returns (uint256) {
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(PRICE_FEED_ID, 300);
        int256 fullPrice = int256(price.price);
        if (fullPrice < 0) revert PriceConverter__NegativePrice();

        return uint256(fullPrice);
    }

    // Update the price feed
    function updatePrice(bytes[] memory pythPriceUpdate) public payable {
        uint256 updateFee = pyth.getUpdateFee(pythPriceUpdate);
        pyth.updatePriceFeeds{value: updateFee}(pythPriceUpdate);
    }

    // Update the price feed and get the updated ETH/USD price
    function UpdateAndGetEthUsdPrice(bytes[] memory pythPriceUpdate) public payable returns (uint256) {
        updatePrice(pythPriceUpdate);
        uint256 currentPrice = getEthUsdPrice();

        return currentPrice;
    }

    
}

/**
 * // Get the current ETH/USD price
    function getEthUsdPrice() public view returns (uint256) {
        PythStructs.Price memory price = pyth.getPriceUnsafe(PRICE_FEED_ID); //getPriceNoOlderThan(PRICE_FEED_ID, 300);
        int256 fullPrice = int256(price.price);
        if (fullPrice < 0) revert PriceConverter__NegativePrice();

        return uint256(fullPrice);
    }
 * 
 */
