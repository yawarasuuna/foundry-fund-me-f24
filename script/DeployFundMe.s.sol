// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfirg.s.sol";

contract DeployFundMe is Script, HelperConfig {
    // function run() external {
    // vm.startBroadcast();
    // new FundMe();
    // vm.stopBroadcast();

    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); // before vm.startB bc we dont want to waste gas deploying it on a real chain, its only simulated, and it isnt sent with a tx
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // if struct had multiple variables, we'd use (address ethUsdPriceFeed, , , )
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}

// mock contracts
