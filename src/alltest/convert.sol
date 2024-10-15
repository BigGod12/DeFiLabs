// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IWETH.sol";

interface IVic {
    function convertTo(uint256 amount, address to) external payable;
    function getMetisByVestingDuration(uint256 amount, uint256 duration) external view returns (uint256);
}

interface IXGrailTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

interface Iwmetis {
    function deposit() external payable;
    function balanceOf(address owner) external view returns (uint);
}
contract AliendefferTest is Test {
    address public me;

    IVic private vic = IVic(0xcA042eA7E9AA901C85d5afA5247a79E935dB4996);
    IERC20 private xxmetis = IERC20(0xcA042eA7E9AA901C85d5afA5247a79E935dB4996);
    Iwmetis private wmatis = Iwmetis(0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481);

    function setUp() public {
        vm.createSelectFork("https://andromeda-rpc.metis.io", 18149612);
        me = msg.sender;
        
        vm.deal(address(this), 100 ether);

        vm.prank(address(this));
        wmatis.deposit{value: 90 ether}();
    }

    function testTest() external payable {
        emit log_named_decimal_uint("new token mined", wmatis.balanceOf(address(this)), 18);
        convertToXMetis();

        emit log_named_decimal_uint("new token mined", xxmetis.balanceOf(address(this)), 18);
    }

    uint256 amount = 50 ether;

    function convertToXMetis() public payable {
        logMetisByVestingDuration();

        vic.convertTo(amount, address(this));

        // (bool success, ) = address(wmatis).call{value: amount}(
        //     abi.encodeWithSignature("convertTo(uint256,address)", amount, address(this))
        // );
        // require(success, "convertTo: conversion failed");
    }

    // function prev() internal view {
    //     uint256 amounttodp = 1000;
    //     uint256 duration = 365 days; // example duration
    //     uint256 result = vic.getMetisByVestingDuration(amounttodp, duration);
    //     emit log_named_decimal_uint("new token mined", result, 18);
        
    // }

    function logMetisByVestingDuration() public view {
        uint256 duration = 365;
        uint256 metis = vic.getMetisByVestingDuration(amount, duration);
        console.log("Metis amount for vesting duration:", metis);
    }



    // Fallback function to receive ETH
    receive() external payable {}
}
