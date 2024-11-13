// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 1. Deploys mocks on a local anvil chain
// 2. Keeps track of contract addresses acrros different chains

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// if locally anvil, deploys mocks, else, grags address from live network;

// needs to impost Script to use vm
contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig; // public variable; now we can select the network

    uint8 public constant MAGIC_DEC = 8;
    int256 public constant MAGIC_INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthconfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetconfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthconfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306}); // since it is a struct, we use {} specify type and object;
        return sepoliaConfig;
    } // returns configurations for everyything we need from Sepolia // memory bc its a special object struct

    function getEthMainnetconfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419}); // since it is a struct, we use {} specify type and object;
        return ethConfig;
    } // returns configurations for everyything we need from Sepolia // memory bc its a special object struct

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // if using vm, it cant be pure
        if (activeNetworkConfig.priceFeed != address(0)) {
            // if priceFeed was set up at any point, just return and continue using current one instead of running the rest of the function; if address is default (0), run it;
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(MAGIC_DEC, MAGIC_INITIAL_PRICE); // 8, 2000e8 are magic numbers; constructor from MockV3Aggregator takes _decimals and _initialAnswer, so we need to include them here. ETH/USD has 8 dec, starts at USD2000/eth
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}

// mock contracts placed under new folder under test, due to them being different from our codebase
