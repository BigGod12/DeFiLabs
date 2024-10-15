pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC3156FlashBorrower.sol";
import "../interface.sol";


contract AllienFlashTest is Test {
    address private constant usbd = 0x4300000000000000000000000000000000000003;
    address private constant blast = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad;
    address private constant weth = 0x4300000000000000000000000000000000000004;
    // IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    Uni_Router_V2 ThrusterRouter = Uni_Router_V2(0x98994a9A7a2570367554589189dC9772241650f6);

      function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6210720);
        vm.deal(address(this), 100.1 ether);
        vm.prank(address(this));
        IWETH(0x4300000000000000000000000000000000000004).deposit{value: 50 ether}();
        deal(address(usbd), address(this), 100 ether);
    }


    function testExploit() public {
        weth.approve(address(ThrusterRouter), blast.balanceOf(address(this)));

        // Proceed to swap the output token for WETH
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(blast);
    
        blast.approve(address(ThrusterRouter), blast.balanceOf(address(this)));

        uint256 amountOutBlast = blast.balanceOf(address(this)); // Exact amount of BLAST you want
uint256 amountInMaxWeth = weth.balanceOf(address(this)); // Max WETH you're willing to spend

// Swap WETH for BLAST
ThrusterRouter.swapTokensForExactTokens(
    amountOutBlast,
    amountInMaxWeth,
    path,
    address(this),
    block.timestamp + 30
);

    }

}