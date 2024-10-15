
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";


contract XXXExploit is Test {

    uint256 private constant STORAGE_SLOT = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
    address private constant conToRead = 0x35fC556d6f8675B26fDF1542e6E894100155B34E;

    // Event to log the result
    event StorageRead(address indexed target, uint256 slot, uint256 value);
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
    }


    function testExploit() public {

        readStorage(conToRead,STORAGE_SLOT);
        
    }
    // Function to read storage from a specific slot in another contract and emit the result
    function readStorage(address target, uint256 slot) public returns (uint256) {
        uint256 result;
        assembly {
            // Load the value from the target contract's storage slot
            result := sload(add(slot, mul(target, 0x100000000000000000000000000000000)))
        }
        emit StorageRead(target, slot, result);
        return result;
    }

}


pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract ProxyStorageTest is Test {
    address proxy = 0xYourProxyAddress;
    
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
    }
    function testInitializedSlot() public {
        // Calculate the slot for initialization flag (keccak256("eip1967.proxy.initialized") - 1)
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.initialized")) - 1);

        // Load the value of the initialization flag from the proxy's storage
        bytes32 initializedFlag = vm.load(proxy, slot);

        // Check if the proxy is initialized (non-zero means initialized)
        bool isInitialized = initializedFlag != bytes32(0);
        emit log_bool(isInitialized);
    }
}

