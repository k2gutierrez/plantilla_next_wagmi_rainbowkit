// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {NFT} from "src/other/NFT.sol";
import {MockPyth} from "lib/pyth-sdk-solidity/MockPyth.sol";

abstract contract CodeConstants {
    /* NFT values */
    string public constant NAME = "MINGLES";
    string public constant SYMBOL = "MGS";
    address public constant PYTH_PRICEFEED_CONTRACT = 0x2880aB155794e7179c9eE2e38200202908C17B43;

    //uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_APE_CHAIN_ID = 33139;
    uint256 public constant ETH_CURTIS_CHAIN_ID = 33111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    bytes32 public constant PYTH_PRICE_FEED_ID = 0x15add95022ae13563a11992e727c91bdb6b55bc183d9d747436c80a483d8c864;
    bytes32 public constant ETH_PRICE_FEED_ID = bytes32(uint256(0x1));
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address _contract;
        uint256 _supply;
        uint256 _externalSupply;
        uint256 _mintPrice;
        address _priceFeedContract;
        bytes32 _priceFeed;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_CURTIS_CHAIN_ID] = getCurtisEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId]._contract != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getCurtisEthConfig() public pure returns (NetworkConfig memory) {
        // Deploy NFT
        // vm.startBroadcast();
        // NFT nft = new NFT(NAME, SYMBOL);
        // vm.stopBroadcast();
        return
            NetworkConfig({
                _contract: address(0), //address(nft),
                _supply: 5555,
                _externalSupply: 100,
                _mintPrice: 15e18, // price as USD value
                _priceFeedContract: PYTH_PRICEFEED_CONTRACT,
                _priceFeed: PYTH_PRICE_FEED_ID
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig._contract != address(0)) {
            return localNetworkConfig;
        }

        // Deploy mocks
        vm.startBroadcast();
        NFT nft = new NFT(NAME, SYMBOL);
        MockPyth mockPyth = new MockPyth(60, 1);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            _contract: address(nft),
            _supply: nft.getTotalSupply(),
            _externalSupply: 100,
            _mintPrice: nft.getMintPrice(),
            _priceFeedContract: address(mockPyth),
            _priceFeed: ETH_PRICE_FEED_ID
        });

        return localNetworkConfig;
    }

}
