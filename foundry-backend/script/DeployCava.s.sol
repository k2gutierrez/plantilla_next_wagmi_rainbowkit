// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Cava} from "src/Cava.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
//import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployCava is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns(Cava, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Cava cava = new Cava(
            config._contract,
            config._supply,
            config._externalSupply,
            config._mintPrice,
            config._priceFeedContract,
            config._priceFeed
        );
        vm.stopBroadcast();

        return (cava, helperConfig);
    }

}