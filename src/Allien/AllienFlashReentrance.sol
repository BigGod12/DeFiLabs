// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IWETH.sol";
import "./test/interfaces/IUni_Pair_V2.sol";

contract ThrusterFlashloanTest is Test {
    using SafeMath for uint;
    IUni_Pair_V2 private pair = IUni_Pair_V2(0x12c69BFA3fb3CbA75a1DEFA6e976B87E233fc7df);
    address private constant token0 = 0x4300000000000000000000000000000000000004; // WETH
    address private constant token1 = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad; // BLAST

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6201355);
        vm.deal(address(this), 10.1 ether);
        vm.prank(address(this));
        IWETH(token0).deposit{value: 1 ether}();
    }

    function testloan() public {
        emit log_named_decimal_uint("token0 before pair", IERC20(token0).balanceOf(address(pair)), 18);
        emit log_named_decimal_uint("token0 for contract", IERC20(token0).balanceOf(address(this)), 18);
        
        // Swap token0 for token1 using the pair's token0 balance
        uint256 amount0ToSwap = IERC20(token0).balanceOf(address(pair));
        IERC20(token0).transfer(address(pair), amount0ToSwap);
        pair.swap(0, amount0ToSwap, address(this), new bytes(0));
        
        emit log_named_decimal_uint("token1 after swap", IERC20(token1).balanceOf(address(pair)), 18);

        bytes memory data = abi.encode(token1, 10 * 10**18);
        pair.swap(0, 10 * 10**18, address(this), data);

        emit log_named_decimal_uint("token1 after flashloan", IERC20(token1).balanceOf(address(this)), 18);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        emit log_named_decimal_uint("token1 during flash", IERC20(token1).balanceOf(address(this)), 18);
        
        // calculate fee for the loan
        uint256 fee = (uint256(10 * 10**18) * 3) / 997 + 1;
        emit log_named_decimal_uint("fee to pay during ", fee, 18);
        uint256 amountToRepay = 10 * 10**18 + fee;
        emit log_named_decimal_uint("flash loan amount to repay", amountToRepay, 18);

        // Ensure we have enough balance to repay the loan
        require(IERC20(token1).balanceOf(address(this)) >= amountToRepay, "Insufficient balance to repay the loan");
        
        // Repay the loan
        IERC20(token1).transfer(address(pair), amountToRepay);
    }

    receive() external payable {}
}
