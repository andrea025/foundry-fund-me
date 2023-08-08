// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FundMe} from "src/FundMe.sol";

contract DeployFundMe is Script {

    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); 
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        //vm.createSelectFork("sepolia");
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
