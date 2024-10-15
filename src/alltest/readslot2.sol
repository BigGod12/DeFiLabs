// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";


contract ProxyStorageTest is Test {
    address proxy = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
    }
    event InitializedStatus(bool isInitialized);

    function testInitializedSlot() public {
        // Calculate the slot for initialization flag (keccak256("eip1967.proxy.initialized") - 1)
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

        // Load the value of the initialization flag from the proxy's storage
        bytes32 initializedFlag = vm.load(proxy, slot);

        // Check if the proxy is initialized (non-zero means initialized)
        bool isInitialized = initializedFlag != bytes32(0);

        // Emit a custom event to log the result
        emit InitializedStatus(isInitialized);
    }
}

