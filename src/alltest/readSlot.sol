
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";


contract XXXExploit is Test {

    uint256 private constant STORAGE_SLOT = 0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2;
    address private constant conToRead = 0x59C7C832e96D2568bea6db468C1aAdcbbDa08A52;

    // Event to log the result
    event StorageRead(address indexed target, uint256 slot, uint256 value);
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://developer-access-mainnet.base.org", 20295659);
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

